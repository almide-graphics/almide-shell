# Sourced inside the container: a Hyprland session as user u — seatd,
# Hyprland on vkms at output scale $SCALE (default 2), a session bus, and
# PipeWire with one null sink at 42 %. Leaves in the environment:
#   ENVS    the exports a command run as u needs (prefix: su u -c "$ENVS cmd")
#   LW, LH  the output's size in surface units (the virtual pointer's extent)
seatd -g video > /tmp/seatd.log 2>&1 &
sleep 0.5
mkdir -p /tmp/xdg && chown u /tmp/xdg && chmod 700 /tmp/xdg
mkdir -p /home/u/.config/hypr
SCALE=${SCALE:-2}
# The output in surface units: what the virtual pointer's extent is.
LW=$(awk "BEGIN { print int(1024 / $SCALE + 0.5) }")
LH=$(awk "BEGIN { print int(768 / $SCALE + 0.5) }")
# A scenario's own settings (key bindings, autostart) go in extra.conf.
touch /home/u/.config/hypr/extra.conf
cat > /home/u/.config/hypr/hyprland.conf <<CONF
source = /home/u/.config/hypr/extra.conf
monitor = , 1024x768, 0x0, $SCALE
misc {
  disable_hyprland_logo = true
  disable_splash_rendering = true
}
ecosystem {
  no_update_news = true
  no_donation_nag = true
}
animations {
  enabled = false
}
general {
  gaps_out = 8
}
CONF
chown -R u /home/u
su u -c 'export XDG_RUNTIME_DIR=/tmp/xdg LIBSEAT_BACKEND=seatd; Hyprland > /tmp/hypr.log 2>&1 &'
for i in $(seq 100); do ls /tmp/xdg/hypr/*/.socket2.sock >/dev/null 2>&1 && break; sleep 0.1; done
for i in $(seq 100); do ls /tmp/xdg | grep -q "^wayland-[0-9]*$" && break; sleep 0.1; done
SIG=$(ls /tmp/xdg/hypr | head -1)
WD=$(ls /tmp/xdg | grep "^wayland-[0-9]*$" | head -1)
ENVS="export XDG_RUNTIME_DIR=/tmp/xdg HYPRLAND_INSTANCE_SIGNATURE=$SIG WAYLAND_DISPLAY=$WD TZ=${TZ:-Asia/Tokyo};"
su u -c "$ENVS hyprctl dismissnotify >/dev/null"
# Audio: PipeWire and WirePlumber on a session bus, one null sink at 42 %.
su u -c "$ENVS dbus-daemon --session --address=unix:path=/tmp/xdg/bus --fork >/dev/null"
ENVS="$ENVS export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/xdg/bus;"
su u -c "$ENVS pipewire > /tmp/pw.log 2>&1 & sleep 0.5; wireplumber > /tmp/wp.log 2>&1 &"
sleep 1.5
su u -c "$ENVS pw-cli create-node adapter '{ factory.name=support.null-audio-sink node.name=almide-null media.class=Audio/Sink object.linger=true audio.position=[FL FR] }' >/dev/null"
sleep 1
su u -c "$ENVS wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.42; wpctl get-volume @DEFAULT_AUDIO_SINK@"
