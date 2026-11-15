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
#
# The rate 48000 lines are the seat's measured audio fact, not a style choice:
# this board's I2S -> HDMI link only clocks correctly for the 48 kHz family,
# and any 44.1 kHz-family rate the applications ask for arrives about 2.6x
# too fast on the DMA, which sounds pitch-shifted, garbled and full of
# underruns. So the plug has to RESAMPLE: a bare slave.pcm passes the engine's
# own 11-22 kHz mono or the 44100 of OpenAL and friends straight to hw:0,0 and
# every one of them garbles; naming rate 48000 format S16_LE channels 2 in the
# slave makes alsa-lib convert before the DMA and Doom, Heretic, Hexen, the
# OpenNOW streamer and UT99 all play clean. ut99 even states the fact in its
# own log: "Can't set OutputRate of 44100, using system (OS) defaults of 48000".
do_install:append() {
    printf '%s\n' '' '# Added by meta-watermelon-wine: alsa-lib default PCM, so' '# snd_pcm_open("default") resolves instead of failing -EHOSTDOWN.' '' 'pcm.!default {' '    type plug' '    slave {' '        pcm "playback_hdmi"' '        rate 48000' '        format S16_LE' '        channels 2' '    }' '}' '' 'ctl.!default {' '    type hw' '    card STM32MP25DK' '}' >> ${D}${sysconfdir}/asound-stm32mp25yx-dk.conf
    printf '%s\n' '' '# Added by meta-watermelon-wine: alsa-lib default PCM (EV1 card).' '' 'pcm.!default {' '    type plug' '    slave {' '        pcm "playback_hdmi"' '        rate 48000' '        format S16_LE' '        channels 2' '    }' '}' '' 'ctl.!default {' '    type hw' '    card STM32MP25EV1' '}' >> ${D}${sysconfdir}/asound-stm32mp25yx-ev1.conf
}
