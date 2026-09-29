#!/bin/bash
# Inside the container: start Hyprland, run the bar and two windows on
# different workspaces, switch between them, click the bar, and capture.
#   SCALE=2 capture.sh OUT.png
# SCALE is the output's scale (default 2, a laptop's dense screen; 1.6 takes
# the fractional path; 1 a plain one) on vkms's 1024x768.
set -u
OUT=$1
ALMIDE=/almide/build/release/almide
mkdir -p /w && cd /shell && tar --exclude=./target -cf - . | (cd /w && tar -xf -)
# snaidhm from the checkout mounted at /snaidhm, not from its remote.
mkdir -p /snaidhm-copy && cd /snaidhm && tar --exclude=./target -cf - . | (cd /snaidhm-copy && tar -xf -)
sed -i 's|^snaidhm = .*|snaidhm = { path = "/snaidhm-copy" }|' /w/almide.toml
rm -f /w/almide.lock
chown -R u /w /snaidhm-copy
cd /w
$ALMIDE build main.almd -o /tmp/bar 2>&1 | tail -1
$ALMIDE build notifyd.almd -o /tmp/notifyd 2>&1 | tail -1
$ALMIDE build launcher.almd -o /tmp/launcher 2>&1 | tail -1
$ALMIDE build osd.almd -o /tmp/osd 2>&1 | tail -1
(cd /snaidhm-copy && $ALMIDE build examples/wayland/main.almd -o /tmp/win 2>&1 | tail -1 && $ALMIDE build examples/wayland/drive.almd -o /tmp/drive 2>&1 | tail -1)
chmod 755 /tmp/bar /tmp/notifyd /tmp/launcher /tmp/osd /tmp/win /tmp/drive
# Applications for the launcher to find.
mkdir -p /home/u/.local/share/applications
for app in "almide-window|Almide Window|/tmp/win 20000|A window written in Almide" "files|Files|true|Browse the file system" "settings|設定|true|システムの設定" "terminal|Terminal|true|Command line" "hidden|Hidden|true|"; do
  IFS='|' read id name exec comment <<< "$app"
  extra=""; [ "$id" = hidden ] && extra="NoDisplay=true"
  printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s %%U\nComment=%s\n%s\n' "$name" "$exec" "$comment" "$extra" > /home/u/.local/share/applications/$id.desktop
done
chown -R u /home/u/.local
seatd -g video > /tmp/seatd.log 2>&1 &
sleep 0.5
mkdir -p /tmp/xdg && chown u /tmp/xdg && chmod 700 /tmp/xdg
mkdir -p /home/u/.config/hypr
SCALE=${SCALE:-2}
# The output in surface units: what the virtual pointer's extent is.
LW=$(awk "BEGIN { print int(1024 / $SCALE + 0.5) }")
LH=$(awk "BEGIN { print int(768 / $SCALE + 0.5) }")
cat > /home/u/.config/hypr/hyprland.conf <<CONF
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
su u -c "$ENVS /tmp/bar > /tmp/bar.log 2>&1 &"
su u -c "$ENVS /tmp/notifyd > /tmp/notifyd.log 2>&1 &"
sleep 1
su u -c "$ENVS /tmp/win 20000 > /tmp/win1.log 2>&1 &"
sleep 1
su u -c "$ENVS hyprctl dispatch workspace 3 >/dev/null; /tmp/win 20000 > /tmp/win2.log 2>&1 &"
sleep 1.5
su u -c "$ENVS hyprctl dismissnotify >/dev/null; grim /out/before-click.png"
# Click workspace 1's button on the bar (the first piece, at the left edge).
su u -c "$ENVS /tmp/drive extent $LW $LH move 24 15 sleep 200 click sleep 300" >/dev/null
sleep 1
su u -c "$ENVS hyprctl dismissnotify >/dev/null; grim $OUT"
# Notifications, through the bus as any app sends them.
su u -c "$ENVS gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.GetServerInformation"
su u -c "$ENVS notify-send -t 20000 'Build finished' 'almide-shell: 12 tests passed in 3.1 s'"
su u -c "$ENVS notify-send -t 20000 'メッセージ' '通知デーモンも Almide です。D-Bus のワイヤプロトコルから書いています。長い本文は折り返して表示されます。'"
ID=$(su u -c "$ENVS notify-send -p -t 20000 'Will be closed' 'by CloseNotification'")
sleep 0.5
su u -c "$ENVS grim /out/notifications.png"
su u -c "$ENVS gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.CloseNotification $ID" >/dev/null
sleep 0.5
su u -c "$ENVS grim /out/after-close.png"
# Idle cost: the bar's CPU time over 20 idle seconds (clock ticks per minute,
# volume read every 5 s, battery every 30 s).
BAR=$(pgrep -u u -x bar | head -1)
T0=$(awk '{print $14+$15}' /proc/$BAR/stat); sleep 20; T1=$(awk '{print $14+$15}' /proc/$BAR/stat)
echo "idle: $((T1 - T0)) clock ticks of CPU in 20 s (of $((20 * $(getconf CLK_TCK))))"
echo "rss: $(awk '/VmRSS/{print $2, $3}' /proc/$BAR/status)"
su u -c "$ENVS hyprctl activeworkspace -j" | grep '"id"' | head -1
# The OSD: the first command starts the daemon, the next ones go to it.
su u -c "$ENVS /tmp/osd volume +8 > /tmp/osd.log 2>&1 &"
sleep 1
su u -c "$ENVS /tmp/osd volume +8; wpctl get-volume @DEFAULT_AUDIO_SINK@"
sleep 0.3
su u -c "$ENVS grim /out/osd-volume.png"
su u -c "$ENVS /tmp/osd volume mute; wpctl get-volume @DEFAULT_AUDIO_SINK@"
sleep 0.3
su u -c "$ENVS grim /out/osd-muted.png"
su u -c "$ENVS /tmp/osd volume mute"
sleep 2
su u -c "$ENVS hyprctl layers" | grep -c almide-osd | sed 's/^/osd layers after 2 s: /'
su u -c "$ENVS /tmp/osd brightness +5; /tmp/osd louder" 2>&1 | head -1
# The launcher: type, pick, start.
su u -c "$ENVS hyprctl dispatch workspace 5 >/dev/null"
su u -c "$ENVS WAYLAND_DEBUG=${CLIENT_DEBUG:-} /tmp/launcher > /tmp/launcher.log 2>&1 &"
sleep 1
su u -c "$ENVS hyprctl monitors" | grep -E "scale"
su u -c "$ENVS hyprctl layers" | grep -E "namespace"
su u -c "$ENVS grim /out/launcher-open.png"
su u -c "$ENVS wtype alm"
sleep 0.5
su u -c "$ENVS grim /out/launcher-typed.png"
su u -c "$ENVS wtype -k Return"
sleep 2
su u -c "$ENVS grim /out/launched.png"
su u -c "$ENVS hyprctl clients" | grep -E "class|workspace" | head -8
echo "--- bar"; cat /tmp/bar.log
echo "--- launcher"; cat /tmp/launcher.log | grep -v "wayland\]"
echo "--- notifyd"; cat /tmp/notifyd.log
echo "--- osd"; cat /tmp/osd.log
echo "--- hypr errors"; grep -i -E "error|crash" /tmp/hypr.log | head -5
