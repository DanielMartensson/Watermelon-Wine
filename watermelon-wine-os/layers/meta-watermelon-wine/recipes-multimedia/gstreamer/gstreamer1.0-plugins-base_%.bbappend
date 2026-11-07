# One OS-level switch for this board: the seat's audio path. OpenNOWLite hands
# the vendor's Opus packets straight to GStreamer, whose decoder element for
# them is built by this recipe's opus feature. OpenSTLinux leaves that feature
# off its default PACKAGECONFIG list (the build then configures -Dopus=disabled,
# which is why the deployed image has no libgstopus.so and no opus element), so
# the element has to be turned on here rather than in an app recipe.
#
# opennow-streamer's NVST transport negotiates Opus 48 kHz stereo for game audio
# on every cloud session, so this feature is what makes that audio playable on
# the board at all; libopus is pulled in as a build dependency by the feature
# and libopus0 is already in the image as its runtime library.
PACKAGECONFIG:append = " opus"
