# imwebbrowser dlopen:ar "libWPEBackend-fdo-1.0.so" (oversionerad), en symbol
# som annars bara lever i -dev-paketet. Lägg den i runtime-paketet i stället.
do_install:append() {
    # Se till att soname-länken (libWPEBackend-fdo-1.0.so.1) finns; skapa den
    # från den versionsbundna filen om paketen bara tar med *.so.1.<x>.<y>.
    if [ ! -e ${D}${libdir}/libWPEBackend-fdo-1.0.so.1 ]; then
        found=$(ls -1 ${D}${libdir}/libWPEBackend-fdo-1.0.so.1.* 2>/dev/null | head -n1)
        [ -n "$found" ] && ln -sf "$(basename "$found")" ${D}${libdir}/libWPEBackend-fdo-1.0.so.1
    fi
    ln -sf libWPEBackend-fdo-1.0.so.1 ${D}${libdir}/libWPEBackend-fdo-1.0.so
}

# Hindra att symbolen sveps med till -dev-paketet (default-FILES lägger
# lib*.so i FILES_SOLIBSDEV); den måste ligga i runtime-paketet.
# Borttagen från FILES_SOLIBSDEV först — utan det vinner -dev trots
# tillägget i FILES:${PN}, och länken landar aldrig i rootfs.
FILES_SOLIBSDEV:remove = "${libdir}/libWPEBackend-fdo-1.0.so"
FILES:${PN} += "${libdir}/libWPEBackend-fdo-1.0.so"