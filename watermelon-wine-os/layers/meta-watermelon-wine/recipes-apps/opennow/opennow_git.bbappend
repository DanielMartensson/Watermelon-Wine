# Machine-specific configuration for OpenNOW on STM32MP25x.
#
# The opennow recipe in meta-embedded-apps is machine-agnostic and defaults to
# no optional decode backend, so it builds on any Linux machine. The choice that
# belongs to this SoC lives here instead of there.
#
# Why no VA-API backend on STM32MP25x
# ----------------------------------
# The VDEC is a Hantro G1 exposed as a stateful V4L2 memory-to-memory decoder,
# and that is the only interface the driver offers. In the ST kernel
# (v6.6-stm32mp-r3.1, the 6.6.129 tree this BSP builds) that is visible in
# drivers/media/platform/verisilicon:
#
#   - Kconfig: VIDEO_HANTRO depends on V4L_MEM2MEM_DRIVERS and selects
#     V4L2_MEM2MEM_DEV.
#   - Makefile: one module, hantro-vpu.o. There is no separate stateless or
#     request-API object.
#   - hantro_drv.c registers through v4l2_m2m_init() and queues
#     V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE for H.264_SLICE and
#     V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE for the decoded frames.
#
# No node in that tree advertises V4L2_CAP_VIDEO_CODEC_STATELESS. A
# libva-v4l2-request driver binds to exactly such a node, so it has nothing to
# open here and cannot be used, however the user-space side is packaged.
# Enabling the "linux-vaapi" cargo feature would compile video/vaapi.rs, which
# reaches the decoder through DRM PRIME and therefore needs that node. It would
# be probed before the V4L2 backend, since the client tries Vulkan, Cuda, VaApi,
# V4l2, Ffmpeg in that order, and a failing probe can mask the backend that does
# work.
#
# What is left
# ------------
# video/v4l2.rs, the stateful V4L2 M2M backend, needs no cargo feature at all:
# src/video/mod.rs declares "mod v4l2;" with no #[cfg]. Presentation still needs
# Vulkan, which opennow-streamer-platform-linux enables through its own
# default = ["vulkan"]. So the correct feature list is empty, which is also the
# layer default, and this file only states that explicitly.
#
# Consequences that follow from the VDEC, for whoever debugs playback:
#   - H.264 only. stm32mp25_vdec_variant advertises HANTRO_H264_DECODER,
#     HANTRO_VP8_DECODER and HANTRO_JPEG_DECODER and nothing else, so there is
#     no HEVC and no AV1. The client's default preference is
#     AV1 -> HEVC -> H.264, and with V4L2 the only entry it reports, that
#     resolves to H.264 on its own.
#   - 8-bit 4:2:0 SDR NV12, up to 1920x1088 at 60 fps. 4K, 10-bit and 4:4:4
#     must be ruled out.
#   - Decoded frames are copied to the CPU. video/v4l2.rs allocates
#     V4L2_MEMORY_MMAP buffers and returns planes with dmabuf: None, so
#     frame_producer.rs takes its PreparedLinuxFrame::Cpu path and the frames
#     are uploaded to a Vulkan buffer. That costs one NV12 memcpy per frame on
#     the dual Cortex-A35, and in exchange the build does not depend on the GPU
#     driver advertising VK_EXT_image_drm_format_modifier, which the bundled
#     gcnano driver does not. Zero-copy is a possible later optimisation, not a
#     prerequisite.
#   - The M2M node must offer NV12 or I420 on its capture queue. That is what
#     video/v4l2.rs negotiates, and the kernel source says NV12 is registered,
#     but only a running node proves it. v4l2-m2m-probe in this layer reports
#     which of the client's five probe checks pass, per node.
#
# The backend is not pinned in the launcher. The client reports what it found
# and the user picks one in the UI, so there is nothing to pre-select here.

OPENNOW_CARGO_FEATURES := ""

# The VDEC is reached through a device node, so the client has to be able to
# open /dev/video*. On a desktop or phone that is obvious; on this image it
# depends on the udev rules in place.
# OPENNOW_VK_DRIVER_FILES and friends are left at their defaults: the loader
# finds the VeriSilicon ICD from /etc/vulkan/icd.d/VeriSilicon_icd.json on its
# own.
