# Weston user unit environment override (meta-watermelon-wine)
#
# meta-st-openstlinux / openembedded-core ship weston.service with
# XDG_RUNTIME_DIR=/home/weston, which is invalid. weston.socket listens on
# /run/user/1000/wayland-0, so the wrong XDG_RUNTIME_DIR makes the Wayland
# socket path invalid and app launches from the UI abort.
#
# This overrides the installed user unit with the corrected
#   XDG_RUNTIME_DIR=/run/user/1000
#   LANG=C.UTF-8
# so weston can launch apps from the UI (HDMI / computer use).
#
# The fix lives in this user layer (meta-watermelon-wine), NOT in the upstream
# meta-st checkout, so it survives a repo sync. The base weston-init package
# installs weston.service to ${systemd_user_unitdir}; this append re-installs
# it (last wins) with the corrected content.
#
# NOTE: In this bitbake (2.8.1), a relative file:// SRC_URI entry is resolved
# against the base recipe's FILEPATH (the oecore wayland dir + variant
# subdirs), NOT the bbappend location, so "file://weston-user.service" fails
# with "file could not be found". The variables ${thisdir}/${thisfile} are not
# defined here, and bbappend ":append" joins values with a space (wrong
# separator for the colon-separated FILEPATH), so an explicit absolute path
# is used instead.
WESTON_USER_SERVICE := "/home/ubuntu/Dokument/Github/Watermelon-Wine/watermelon-wine-os/layers/meta-watermelon-wine/recipes-st/images/weston-init/weston-user.service"
SRC_URI:append = " file://${WESTON_USER_SERVICE}"
#
do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -D -p -m0644 ${WESTON_USER_SERVICE} ${D}${systemd_user_unitdir}/weston.service
    fi
}
