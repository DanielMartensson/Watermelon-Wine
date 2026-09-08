SUMMARY = "ImWebBrowser"
DESCRIPTION = "A minimal, GPU-accelerated kiosk web browser built on SDL3 + Dear ImGui + WPE WebKit."
SECTION = "www-client"
HOMEPAGE = "https://github.com/DanielMartensson/ImWebBrowser"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=19b5c44dd600b05d43b5bb78ad0bd491"

inherit cmake pkgconfig

DEPENDS = " \
	libsdl3 \
	libwpe \
	wpebackend-fdo \
	wpewebkit \
	virtual/egl \
	glib-2.0 \
	wayland \
	libxkbcommon \
"

# Rendering backend: OpenGL ES 3 (default) or Vulkan. The GLES backend needs
# the GLES headers; the Vulkan backend needs the Vulkan loader/headers instead
# (imgui_impl_vulkan carries precompiled SPIR-V, so no shader toolchain).
VULKAN_BACKEND ??= "0"
DEPENDS += "${@bb.utils.contains('VULKAN_BACKEND', '1', \
	'vulkan-headers vulkan-loader', 'virtual/libgles2', d)}"
EXTRA_OECMAKE += "${@bb.utils.contains('VULKAN_BACKEND', '1', \
	'-DIMWB_BACKEND_VULKAN=ON', '-DIMWB_BACKEND_VULKAN=OFF', d)}"
EXTRA_OECMAKE += "-DCMAKE_BUILD_TYPE=Release"

# --- Target (STM32MP257F) hardware decode + GeForce NOW nicely configured ---
# Force H.264 onto the SoC VPU (v4l2slh264dec) and advertise avc1 as the only
# "must be hardware" content type, so sites pick H.264 instead of a codec the
# VPU cannot hardware-decode (which would silently fall to software).
EXTRA_OECMAKE += "-DIMWB_VIDEO_DECODER=v4l2slh264dec"
EXTRA_OECMAKE += "-DIMWB_MEDIA_HW_TYPES='video/mp4; codecs=\"avc1\"'"

# GeForce NOW input bridge: WebRTC data-channel input forwarding (armed at
# runtime only when IMWB_GFN_BRIDGE=1 on the GFN site). On for the target.
EXTRA_OECMAKE:append = " -DENABLE_GFN_INPUT_BRIDGE=ON"

# Lean kiosk preset: no remote Web Inspector, no page cache / nice-to-haves.
# Keeps JS JIT ON (measured ~3 MB, and the A35 is CPU-weak).
EXTRA_OECMAKE:append = " -DENABLE_DEVELOPER_EXTRAS=OFF -DENABLE_PAGE_CACHE=OFF \
    -DENABLE_SMOOTH_SCROLLING=OFF -DENABLE_DNS_PREFETCH=OFF \
    -DENABLE_TEXT_AREAS_RESIZE=OFF"

# WebRTC (GFN etc.): WebKit maps RTCPeerConnection onto GStreamer's webrtcbin.
# The runtime image needs the RTP/webrtc plugins + ICE (libnice) in the rootfs;
# decoding itself then rides on the SoC's GStreamer codecs (STM32 VPU for 1080p).
RDEPENDS:${PN} += " \
	gstreamer1.0 \
	gstreamer1.0-plugins-base \
	gstreamer1.0-plugins-good \
	gstreamer1.0-plugins-bad \
	libnice \
	libdecor \
"

SRCREV = "e299edabcd0b89a886a90b6ec8172630e72ad87b"
BRANCH = "main"
SRC_URI = "git://github.com/DanielMartensson/ImWebBrowser.git;protocol=https;branch=${BRANCH}"

S = "${WORKDIR}/git"
PV = "1.0.0"
