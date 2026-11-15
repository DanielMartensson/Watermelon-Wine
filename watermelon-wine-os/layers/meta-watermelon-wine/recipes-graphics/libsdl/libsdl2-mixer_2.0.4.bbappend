# This is where the seat gets its SDL2_mixer, and it is the games that need it:
# the chocolate-doom recipe in layers/meta-embedded-apps leaves the engine's own
# sound-effects device at its default SNDDEVICE_SB (src/i_sound.c:52), and the
# module that owns SNDDEVICE_SB is the SDL2_mixer one (src/i_sdlsound.c:1120),
# whose only alternative in the engine's table is the pcsound module that wants
# /dev/dsp, which the seat does not have. So the games would have no sound
# effects at all without this library, and it is not enough that the library
# builds: what asks for it is a hard pkg-config probe, PKG_CHECK_MODULES(SDLMIXER,
# [SDL2_mixer >= 2.0.2]) at chocolate-doom's configure.ac:80, which sits in the
# AS_IF of --disable-sdl2mixer at configure.ac:79 so only an explicit --disable
# takes the else branch, and the 2011 SDL2_mixer-2.0.4 release this recipe
# fetches carries no pkgconfig file of its own (its tar listing has neither a
# .pc nor a .pc.in), so the probe stops configure rather than deciding the
# module is optional. What is written below is the .pc that probe reads, in the
# same shape the SDL2 library's own sdl2.pc carries (its Name/Version/Libs
# lines, and layers/openembedded-core/meta/conf/bitbake.conf:781 is where
# cross pkg-config is pointed, at ${STAGING_DIR_HOST}${libdir}/pkgconfig, which
# is where the .pc files of library recipes land through their -dev package and
# is where libsdl2_2.30.1's sdl2.pc is waiting today). The Version: line is
# what the >= 2.0.2 comparison reads and the Name has to be the mixed-case
# SDL2_mixer the probe spells, not the recipe's own lower-case one.
SRC_URI:replace = "http://www.libsdl.org/ https://www.libsdl.org/"

do_install:append() {
    install -d ${D}${libdir}/pkgconfig
    printf '%s\n' \
        '# SDL2_mixer pkg-config source file' \
        '' \
        'prefix=/usr' \
        'exec_prefix=\${prefix}' \
        'libdir=\${exec_prefix}/lib' \
        'includedir=\${prefix}/include' \
        '' \
        'Name: SDL2_mixer' \
        'Description: SDL2 mixer - the SDL audio playback library the games use for their sound effects' \
        'Version: 2.0.4' \
        'Requires:' \
        'Conflicts:' \
        'Libs: -L${libdir} -lSDL2_mixer' \
        'Cflags: -I${includedir}' \
        > ${D}${libdir}/pkgconfig/SDL2_mixer.pc
}
