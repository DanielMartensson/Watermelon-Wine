# SDL3's Wayland driver dlopens libdecor and its decoration plugins at
# runtime; the loadable plugins are named libdecor-plugin-*.so and would land
# in the -dev package with the default FILES split. Pull them into the runtime
# package so --gfn/plain windowed mode gets its frame on Weston.
FILES:${PN} += "${libdir}/libdecor/*.so"