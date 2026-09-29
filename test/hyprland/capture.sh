#!/bin/bash
# Inside the container: start Hyprland, run the bar and two windows on
# different workspaces, switch between them, click the bar, and capture.
#   SCALE=2 capture.sh OUT.png
# SCALE is the output's scale (default 2, a laptop's dense screen; 1.6 takes
# the fractional path; 1 a plain one) on vkms's 1024x768.
set -u
OUT=$1
. /t/build.sh
. /t/session.sh
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
