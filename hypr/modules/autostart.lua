local programs = require("modules/programs")

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("Capsule")
    hl.exec_cmd("xhost +SI:localuser:root")
    h1.exec_cmd("awww-daemon")
end)
