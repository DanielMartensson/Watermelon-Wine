SUMMARY = "Checks whether the STM32MP25 VDEC satisfies OpenNOW's V4L2 M2M requirements"
DESCRIPTION = "OpenNOW decodes H.264 on the STM32MP257F through \
video/v4l2.rs, the stateful V4L2 memory-to-memory backend. That module probes \
/dev/video* when it opens a stream and requires a node that reports streaming \
I/O, is an M2M node, accepts V4L2_PIX_FMT_H264 on its output queue, offers NV12 \
or I420 on its capture queue, and hands out V4L2_MEMORY_MMAP buffers. If no \
node matches, playback fails with no /dev/video* node advertises stateful \
H.264 M2M decode with NV12/I420 output, and the reason is not obvious from \
v4l2-ctl output alone. This tool reports, per node, which of those checks pass \
and lists the fourccs \
both queues actually offer, so a failure can be attributed to one specific \
check rather than guessed at. It allocates one MMAP buffer per queue and \
releases it again, and starts no decoding. It is a diagnostic, not part of the \
image: nothing depends on it."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://v4l2-m2m-probe.c;md5=06fda3eddb37aeb0c44ad69993d2d830"

SRC_URI = "file://v4l2-m2m-probe.c"

# The .c sits next to the .bb, not in a files/ subdirectory, and bitbake's
# default FILESPATH only covers the versioned recipe directories. Without this
# the file:// URIs resolve to nothing and the recipe fails to parse.
FILESEXTRAPATHS:prepend := "${THISDIR}:"

S = "${WORKDIR}"

# inherit cmake is used only for the cross toolchain and ${CC}. There is no
# CMakeLists.txt, so configure is skipped. Keeping the class is still the least
# fragile option: a bare recipe with no build class has no ${CC} at all, and
# INHIBIT_DEFAULT_DEPS would take away the cross gcc that provides it.
inherit cmake
do_configure[noexec] = "1"

# Only linux/videodev2.h and libc. Deliberately no libv4l2, so the probe is not
# filtered by libv4l2's own node list and reports what the kernel says.
do_compile() {
    ${CC} -std=gnu11 -O2 -Wall -Wextra -o v4l2-m2m-probe v4l2-m2m-probe.c
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 v4l2-m2m-probe ${D}${bindir}
}

# Not installed into any image by default. To try it on the board:
#   bitbake -c image v4l2-m2m-probe
# then run it on the device, or add it to IMAGE_INSTALL to keep it around.
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_STRIP = "1"
