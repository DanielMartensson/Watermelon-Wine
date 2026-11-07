# vulkan-tools ships vulkaninfo (+ vkcube, enabled by the ST bbappend) used to
# validate the GCNano/Vivante Vulkan driver on STM32MP25.
# qtwayland + qtwayland-plugins ship the Qt6 QPA "wayland" platform plugin
# (libqwayland-egl.so + libqwayland-generic.so in /usr/lib/plugins/platforms)
# required by nano_browser and ytgst on the weston display; without it the
# apps crash with "no Qt platform plugin".
CORE_IMAGE_EXTRA_INSTALL:append = " \
    vulkan-tools \
    qtwayland \
    qtwayland-plugins \
"
# gstreamer1.0-plugins-base-opus ships libgstopus.so, the Opus element the
# seat's game audio needs: opennow-streamer's NVST transport negotiates Opus
# 48 kHz stereo on every cloud session, and layers/meta-watermelon-wine's
# plugins-base bbappend turns that feature on, so the element the feature
# builds has to be in the rootfs as well or the switch has no effect.
CORE_IMAGE_EXTRA_INSTALL:append = " \
    gstreamer1.0-plugins-base-opus \
"
# The console needs its RAM, not the demo tooling. netdata alone costs
#   netdata.service  20 MB RSS plus /usr/libexec/netdata/plugins.d/python.d.plugin
#   19 MB of python3, and it re-reads /proc every few seconds on a 60 FPS
#   stream, which is CPU the compositor then has to skip frames around.
# ModemManager has no modem on the board. PACKAGE_EXCLUDE drops them from the
# packed rootfs; nothing in the game stack depends on them.
PACKAGE_EXCLUDE:append = " netdata modem-manager-modemsinifo "
