# weston's keyboard panel takes the seat's whole keyboard away from whichever
# client has the focus, so the lite client's game keys never arrive while the
# panel's input-method context is live: the panel answers grab_keyboard and the
# compositor ends the default grab and installs keyboard->input_method_grab
# (compositor/text-backend.c:697, input_method_context_grab_keyboard), whose key
# hook input_method_context_grab_key (:623) answers wl_keyboard.key to
# keyboard->input_method_resource and nothing else - the panel's own wl_keyboard
# resource. Only the default grab answers the focused client at all
# (default_grab_keyboard_key -> weston_keyboard_send_key, libweston/input.c:1050),
# which is why r2.7's round of Nov 8 logged 112 key events on the seat and not
# one of ESC, W, A, S or D among them.
do_install:append() {
    INI="${D}${sysconfdir}/xdg/weston/weston.ini"
    test -f "$INI" || return 0

    # Taking the panel out is not the same as taking its line out:
    # text_backend_configuration (compositor/text-backend.c:1069) reads the
    # [input-method] section's "path" key with wet_get_libexec_path("weston-keyboard")
    # as the default, and an ini with no [input-method] section at all lands on
    # the same default, because weston_config_get_section finds no section and
    # config_section_get_entry (shared/config-parser.c:130) answers no entry.
    # The only value that stops the panel is the empty one: launch_input_method
    # returns on a NULL path at :1001 and on strcmp(path, "") == 0 at :1004. So
    # the key has to be present with an empty value and the section has to exist;
    # commenting meta-st's line would leave the libexec default in force.

    # meta-st's weston.ini ships the key with its value: keep the key, empty the value
    sed -i -e 's,^path=/usr/libexec/weston-keyboard$,path=,' "$INI"
    # the same key kept commented inside the section, so it stays in the section
    sed -i -e '/^\[input-method\]/,/^\[/s,^#path=/usr/libexec/weston-keyboard$,path=,' "$INI"
    # oe-core's weston.ini comments the whole section out: give it one whose path is empty
    grep -q '^\[input-method\]' "$INI" || printf '\n[input-method]\npath=\n' >> "$INI"
}
