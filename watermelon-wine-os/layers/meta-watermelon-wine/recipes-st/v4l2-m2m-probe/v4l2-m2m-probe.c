// SPDX-License-Identifier: MIT
/*
 * v4l2-m2m-probe: does the STM32MP25 VDEC satisfy video/v4l2.rs?
 *
 * OpenNOW decodes H.264 on this SoC through video/v4l2.rs, the stateful V4L2
 * M2M backend. That module probes /dev/video* at open time and gives up on the
 * first node that fails a check, so if nothing matches, playback ends with
 * "no /dev/video* node advertises stateful H.264 M2M decode with NV12/I420
 * output". This tool reports, per node, exactly which of those checks pass.
 *
 * The checks below mirror inspect_device() in
 * opennow-streamer-platform-linux/src/video/v4l2.rs:
 *
 *   1. VIDIOC_QUERYCAP succeeds and reports V4L2_CAP_STREAMING.
 *   2. The node is M2M: V4L2_CAP_VIDEO_M2M_MPLANE, or V4L2_CAP_VIDEO_M2M.
 *   3. The output (encoder-side) queue accepts V4L2_PIX_FMT_H264.
 *   4. The capture (decoder-side) queue offers NV12, NV12M, I420 or I420M.
 *   5. Both queues actually hand out a V4L2_MEMORY_MMAP buffer, which is how
 *      the decoder allocates its buffers and where it copies the pixels out
 *      from. There is no ioctl that reports the per-queue memory model without
 *      allocating, so this check does allocate, then releases it again.
 *
 * A node that passes all five is one that video/v4l2.rs will accept.
 *
 * It opens no stream and starts no decoding, and it releases everything it
 * allocates. It does touch queue state briefly, so run it on an idle system
 * and not while something is already decoding.
 */

#include <errno.h>
#include <fcntl.h>
#include <linux/videodev2.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <unistd.h>

static const char *fourcc_str(uint32_t f)
{
	static char buf[5];

	buf[0] = (char)(f & 0xff);
	buf[1] = (char)((f >> 8) & 0xff);
	buf[2] = (char)((f >> 16) & 0xff);
	buf[3] = (char)((f >> 24) & 0xff);
	buf[4] = '\0';
	return buf;
}

static void fourcc_str_into(char *dst, size_t n, uint32_t f)
{
	snprintf(dst, n, "%s", fourcc_str(f));
}

static bool try_ioctl(int fd, unsigned long request, void *arg)
{
	return ioctl(fd, request, arg) == 0;
}

/* List the fourccs a queue type offers, appending to out. Returns count. */
static int enum_formats(int fd, uint32_t type, uint32_t *out, int max)
{
	struct v4l2_fmtdesc desc;
	int n = 0;

	memset(&desc, 0, sizeof(desc));
	desc.type = type;
	for (desc.index = 0; n < max; desc.index++) {
		if (!try_ioctl(fd, VIDIOC_ENUM_FMT, &desc))
			break;
		if (n < max)
			out[n] = desc.pixelformat;
		n++;
	}
	return n;
}

static bool has_fmt(const uint32_t *list, int n, uint32_t want)
{
	for (int i = 0; i < n; i++)
		if (list[i] == want)
			return true;
	return false;
}

static bool has_mmap(int fd, uint32_t type)
{
	struct v4l2_requestbuffers rb;
	bool ok;

	memset(&rb, 0, sizeof(rb));
	rb.count = 1;
	rb.type = type;
	rb.memory = V4L2_MEMORY_MMAP;
	if (!try_ioctl(fd, VIDIOC_REQBUFS, &rb))
		return false;
	ok = rb.count >= 1;

	/* Release it again so the tool leaves no state behind. */
	memset(&rb, 0, sizeof(rb));
	rb.count = 0;
	rb.type = type;
	rb.memory = V4L2_MEMORY_MMAP;
	try_ioctl(fd, VIDIOC_REQBUFS, &rb);

	return ok;
}

struct verdict {
	const char *name;
	bool pass;
	char detail[192];
};

static void set_detail(struct verdict *v, const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vsnprintf(v->detail, sizeof(v->detail), fmt, ap);
	va_end(ap);
}

static void inspect(const char *path, struct verdict results[5], bool *any)
{
	int fd = open(path, O_RDWR | O_NONBLOCK);
	struct v4l2_capability cap;
	uint32_t caps;
	bool multiplanar;
	uint32_t out_type, cap_type;
	uint32_t out_fmts[64], cap_fmts[64];
	int n_out, n_cap;
	char s[5];

	if (fd < 0) {
		set_detail(&results[0], "open(%s) failed: %s", path, strerror(errno));
		return;
	}

	memset(&cap, 0, sizeof(cap));
	if (!try_ioctl(fd, VIDIOC_QUERYCAP, &cap)) {
		set_detail(&results[0], "VIDIOC_QUERYCAP failed: %s", strerror(errno));
		close(fd);
		return;
	}

	caps = (cap.capabilities & V4L2_CAP_DEVICE_CAPS) ? cap.device_caps
						       : cap.capabilities;

	/* 1. streaming I/O */
	if (caps & V4L2_CAP_STREAMING) {
		results[0].pass = true;
		set_detail(&results[0], "V4L2_CAP_STREAMING present");
	} else {
		set_detail(&results[0], "V4L2_CAP_STREAMING missing");
	}

	/* 2. is it an M2M node? */
	multiplanar = (caps & V4L2_CAP_VIDEO_M2M_MPLANE) != 0;
	if (multiplanar || (caps & V4L2_CAP_VIDEO_M2M)) {
		results[1].pass = true;
		set_detail(&results[1], "%s, driver %s, card %s",
			   multiplanar ? "V4L2_CAP_VIDEO_M2M_MPLANE" : "V4L2_CAP_VIDEO_M2M",
			   cap.driver, cap.card);
		*any = true;
	} else {
		set_detail(&results[1], "neither V4L2_CAP_VIDEO_M2M nor _MPLANE set "
					"(capabilities 0x%08x)",
			(unsigned int)caps);
		/* remaining checks need the queue types */
		close(fd);
		return;
	}

	out_type = multiplanar ? V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE
			       : V4L2_BUF_TYPE_VIDEO_OUTPUT;
	cap_type = multiplanar ? V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE
			       : V4L2_BUF_TYPE_VIDEO_CAPTURE;

	/* 3. H.264 on the output queue */
	n_out = enum_formats(fd, out_type, out_fmts, 64);
	if (has_fmt(out_fmts, n_out, V4L2_PIX_FMT_H264)) {
		results[2].pass = true;
		set_detail(&results[2], "V4L2_PIX_FMT_H264 accepted on the output queue");
	} else {
		set_detail(&results[2], "no V4L2_PIX_FMT_H264 among %d output formats", n_out);
	}

	/* 4. NV12 or I420 on the capture queue */
	n_cap = enum_formats(fd, cap_type, cap_fmts, 64);
	if (has_fmt(cap_fmts, n_cap, V4L2_PIX_FMT_NV12) ||
	    has_fmt(cap_fmts, n_cap, V4L2_PIX_FMT_NV12M)) {
		results[3].pass = true;
		set_detail(&results[3], "NV12 available on the capture queue");
	} else if (has_fmt(cap_fmts, n_cap, V4L2_PIX_FMT_YUV420) ||
		   has_fmt(cap_fmts, n_cap, V4L2_PIX_FMT_YUV420M)) {
		/*
		 * I420 is enough for the probe, but video/v4l2.rs then
		 * negotiates NV12 as the stream pixel format, so flag the
		 * difference rather than reporting a plain pass.
		 */
		results[3].pass = true;
		set_detail(&results[3], "only I420 available, not NV12; the decoder "
					"negotiates NV12, so expect a format mismatch");
	} else {
		set_detail(&results[3], "neither NV12 nor I420 among %d capture formats", n_cap);
	}

	/* 5. MMAP has to be allowed, the decoder copies out of the buffers */
	if (has_mmap(fd, cap_type) && has_mmap(fd, out_type)) {
		results[4].pass = true;
		set_detail(&results[4], "both queues handed out a V4L2_MEMORY_MMAP buffer");
	} else {
		set_detail(&results[4], "a queue refused V4L2_MEMORY_MMAP; the Hantro "
					"vb2_dma_contig_memops supports MMAP, so this "
					"suggests the node is busy or held by another user");
	}

	/* Print the full format lists, the deciding evidence either way. */
	printf("    output queue formats:");
	for (int i = 0; i < n_out && i < 16; i++) {
		fourcc_str_into(s, sizeof(s), out_fmts[i]);
		printf(" %s", s);
	}
	if (n_out == 0)
		printf(" (none)");
	printf("\n    capture queue formats:");
	for (int i = 0; i < n_cap && i < 16; i++) {
		fourcc_str_into(s, sizeof(s), cap_fmts[i]);
		printf(" %s", s);
	}
	if (n_cap == 0)
		printf(" (none)");
	printf("\n");

	close(fd);
}

int main(void)
{
	static const char *const checks[5] = {
		"streaming I/O",
		"stateful M2M node",
		"H.264 on output queue",
		"NV12 or I420 on capture queue",
		"MMAP permitted",
	};
	struct verdict results[5];
	int usable = 0;
	int m2m_nodes = 0;
	char path[64];
	int highest = 0;

	printf("OpenNOW stateful V4L2 M2M probe for the STM32MP25 VDEC\n");
	printf("mirrors inspect_device() in opennow-streamer-platform-linux "
	       "src/video/v4l2.rs\n\n");

	for (int i = 0; i < 32; i++) {
		struct stat st;

		snprintf(path, sizeof(path), "/dev/video%d", i);
		if (stat(path, &st) != 0)
			continue;
		if (i > highest)
			highest = i;

		printf("%s:\n", path);
		for (int c = 0; c < 5; c++) {
			results[c].pass = false;
			results[c].name = checks[c];
			results[c].detail[0] = '\0';
		}
		bool any = false;

		inspect(path, results, &any);
		if (!any) {
			printf("    skipped: not a memory-to-memory node\n\n");
			continue;
		}
		m2m_nodes++;

		bool all = true;
		for (int c = 0; c < 5; c++) {
			printf("    [%s] %-32s %s\n", results[c].pass ? "PASS" : "FAIL",
			       results[c].name, results[c].detail);
			if (!results[c].pass)
				all = false;
		}
		if (all) {
			usable++;
			printf("    => this node satisfies every check; "
			       "video/v4l2.rs can open it\n\n");
		} else {
			printf("    => video/v4l2.rs will reject this node\n\n");
		}
	}

	if (highest == 0) {
		printf("No /dev/video* node found at all.\n");
		printf("Check that CONFIG_VIDEO_HANTRO is enabled in the running kernel:\n");
		printf("  grep HANTRO /boot/config-$(uname -r)   # expect CONFIG_VIDEO_HANTRO=y\n");
		printf("  lsmod | grep hantro\n");
		return 2;
	}

	printf("Summary: %d memory-to-memory node(s) found, %d of them satisfy "
	       "every check.\n", m2m_nodes, usable);
	if (m2m_nodes == 0) {
		printf("No memory-to-memory node at all. H.264 decode through "
		       "video/v4l2.rs cannot start.\n");
		return 1;
	}
	if (usable == 0) {
		printf("The M2M node exists but does not satisfy every check, so "
		       "video/v4l2.rs will reject it.\n");
		return 1;
	}
	printf("Hardware H.264 decode is available through the V4L2 M2M backend.\n");
	return 0;
}
