FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}/6.6:"

SRC_URI:append = " \
    file://tim-pwm.config \
    file://0001-ASoC-stm32-i2s-reprogram-low-kernel-clock.patch \
"

KERNEL_CONFIG_FRAGMENTS:append = " ${WORKDIR}/tim-pwm.config"
