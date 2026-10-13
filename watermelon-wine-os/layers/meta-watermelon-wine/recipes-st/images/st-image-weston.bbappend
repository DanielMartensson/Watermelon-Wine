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