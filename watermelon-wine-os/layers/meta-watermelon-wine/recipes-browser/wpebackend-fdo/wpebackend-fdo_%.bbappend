# imwebbrowser dlopens "libWPEBackend-fdo-1.0.so" (unversioned), a symlink that
# would otherwise only live in the -dev package. Keep it in the runtime package
# instead.
do_install:append() {
    # Make sure the SONAME link (libWPEBackend-fdo-1.0.so.1) exists; create it
    # from the versioned file in case the packages only carry *.so.1.<x>.<y>.
    if [ ! -e ${D}${libdir}/libWPEBackend-fdo-1.0.so.1 ]; then
        found=$(ls -1 ${D}${libdir}/libWPEBackend-fdo-1.0.so.1.* 2>/dev/null | head -n1)
        [ -n "$found" ] && ln -sf "$(basename "$found")" ${D}${libdir}/libWPEBackend-fdo-1.0.so.1
    fi
    ln -sf libWPEBackend-fdo-1.0.so.1 ${D}${libdir}/libWPEBackend-fdo-1.0.so
}

# Stop the -dev package from claiming the symlink. The default FILES point at
# it through TWO patterns: FILES_SOLIBSDEV and ${libdir}/lib*${SOLIBSDEV}.
# Emptying FILES_SOLIBSDEV alone is not enough - the glob in -dev wins anyway
# (PACKAGES ordering gives -dev priority) and the link never reaches the
# rootfs. Drop both patterns for this file and add it to ${PN} explicitly.
FILES_SOLIBSDEV:remove = "${libdir}/libWPEBackend-fdo-1.0.so"
FILES:${PN}-dev:remove = "${libdir}/lib*${SOLIBSDEV}"
FILES:${PN} += "${libdir}/libWPEBackend-fdo-1.0.so"