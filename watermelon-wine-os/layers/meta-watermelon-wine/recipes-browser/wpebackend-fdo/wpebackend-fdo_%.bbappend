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

# Hindra att symbolen sveps med till -dev-paketet. default-FILES pekar på
# symlänken via TVÅ mönster: FILES_SOLIBSDEV och ${libdir}/lib*${SOLIBSDEV}.
# Att bara tömma FILES_SOLIBSDEV räcker inte — glob-mönstret i -dev vinner
# fortfarande (PACKAGES-ordningen ger -dev förtur) och länken hamnar aldrig i
# rootfs. Så vi tar bort båda mönstren för just den här filen och lägger den
# uttryckligen i ${PN}.
FILES_SOLIBSDEV:remove = "${libdir}/libWPEBackend-fdo-1.0.so"
FILES:${PN}-dev:remove = "${libdir}/lib*${SOLIBSDEV}"
FILES:${PN} += "${libdir}/libWPEBackend-fdo-1.0.so"