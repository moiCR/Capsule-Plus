local suppressMaximizeRule = hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})


hl.window_rule({
    name = "spotify-workspace",
    match = {
        class = "Spotify",
    },
    workspace = "special:music"
})

hl.window_rule({
    name = "discord-workspace",
    match = {
        class = "discord",
    },
    workspace = "special:discord"
})



hl.window_rule({
    name = "steam-workspace",
    match = {
        class = "steam",
        title = "^Steam$",
    },
    workspace = "special:steam"
})

hl.window_rule({
    name = "steam-floating-popups",
    match = {
        class = "steam"
    },
    float = true,
})

hl.window_rule({
    name = "bitwarden-floating",
    match = {
        class = "Bitwarden"
    },
    float = true,
})

hl.window_rule({
    name = "steam-main-tile",
    match = {
        class = "steam",
        title = "^Steam$",
    },
    float = false,
})

hl.layer_rule({
    name = "quickshell-settings-blur",
    match = { namespace = "^quickshell:settings$" },
    blur = true,
})

hl.layer_rule({
    name = "quickshell-launcher-blur",
    match = { namespace = "^quickshell:launcher$" },
    blur = true,
})

hl.layer_rule({
    name = "quickshell-wifiprompt-blur",
    match = { namespace = "^quickshell:wifi_prompt$" },
    blur = true,
})
