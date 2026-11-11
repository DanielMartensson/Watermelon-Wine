# The ST machine conf only names the HDMI and DMIC PCMs.  alsa-lib's implicit
# "default" device is what SDL and every other ALSA client opens when it is
# not told a device name, and with no pcm.!default in the conf that becomes
# /etc/asound.conf, snd_pcm_open("default") fails with -EHOSTDOWN ("Host is
# down") even though playback_hdmi, plughw:0,0 and hw:0,0 all open and play.
#
# Point default at the board's one playback PCM, through plug so the engine's
# own rate/format (Quake asks for 11-22 kHz mono) is converted instead of
# rejected by type hw.  The generator that copies this file over
# /etc/asound.conf only does so while that file is the one-line OE dummy, so
# the stanza survives reboots once the image ships it here.
#
# The stanzas are written with printf rather than as file:// fragments: bitbake
# resolves a bbappend's file:// entries against the search path of the .bb it
# appends to (the meta-st recipe's own directory), so a fragment kept in this
# layer would never be found, and dropping one in meta-st would put an OS
# change in the wrong layer.  No heredoc either: the shell parser here reads
# the "card STM32MP25DK" style lines of the stanza as unparsed assignments.
do_install:append() {
    printf '%s\n' '' '# Added by meta-watermelon-wine: alsa-lib default PCM, so' '# snd_pcm_open("default") resolves instead of failing -EHOSTDOWN.' '' 'pcm.!default {' '    type plug' '    slave.pcm "playback_hdmi"' '}' '' 'ctl.!default {' '    type hw' '    card STM32MP25DK' '}' >> ${D}${sysconfdir}/asound-stm32mp25yx-dk.conf
    printf '%s\n' '' '# Added by meta-watermelon-wine: alsa-lib default PCM (EV1 card).' '' 'pcm.!default {' '    type plug' '    slave.pcm "playback_hdmi"' '}' '' 'ctl.!default {' '    type hw' '    card STM32MP25EV1' '}' >> ${D}${sysconfdir}/asound-stm32mp25yx-ev1.conf
}
