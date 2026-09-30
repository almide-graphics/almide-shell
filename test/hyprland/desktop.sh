#!/bin/bash
# Inside the container: the whole shell as a desktop to use — bar,
# notifications, OSD daemon, launcher and a terminal on keys — shown over VNC
# and, for a browser, noVNC on port 6080.
set -u
. /t/build.sh
# ceangal's todo app on its CPU host, when a ceangal checkout is mounted.
# (build.sh copied it to /ceangal-copy.)
if [ -d /ceangal ]; then
  (cd /ceangal-copy && $ALMIDE build --release examples/wayland/main.almd -o /tmp/ceangal 2>&1 | tail -1)
  chmod 755 /tmp/ceangal
fi
# Keys: ALT rather than SUPER, which a browser or VNC viewer keeps for itself.
mkdir -p /home/u/.config/hypr
cat > /home/u/.config/hypr/extra.conf <<'CONF'
# vkms has a cursor plane, and a cursor there is missing from screencopy,
# so from VNC: draw it into the frame instead. (Only here — a benchmark's
# screenshot keeps the pointer out.)
cursor {
  no_hardware_cursors = true
}
env = XCURSOR_THEME,Adwaita
env = XCURSOR_SIZE,24
exec-once = /tmp/bar
# The session bus starts after Hyprland does: name it.
exec-once = env DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/xdg/bus /tmp/notifyd
exec-once = /tmp/osd
bind = ALT, SPACE, exec, /tmp/launcher
bind = ALT, RETURN, exec, foot
bind = ALT, T, exec, /tmp/ceangal
bind = ALT, Q, killactive
bind = ALT, 1, workspace, 1
bind = ALT, 2, workspace, 2
bind = ALT, 3, workspace, 3
bind = ALT, 4, workspace, 4
bind = ALT SHIFT, 1, movetoworkspace, 1
bind = ALT SHIFT, 2, movetoworkspace, 2
bind = ALT SHIFT, 3, movetoworkspace, 3
bind = ALT, UP, exec, /tmp/osd volume +5
bind = ALT, DOWN, exec, /tmp/osd volume -5
bind = ALT, M, exec, /tmp/osd volume mute
bind = ALT, N, exec, notify-send "こんにちは" "Almide の通知デーモンから。$(date +%H:%M:%S)"
bindel = , XF86AudioRaiseVolume, exec, /tmp/osd volume +5
bindel = , XF86AudioLowerVolume, exec, /tmp/osd volume -5
bindl = , XF86AudioMute, exec, /tmp/osd volume mute
CONF
# The input method: fcitx5 with Mozc, switched on with Ctrl+Space (or
# Ctrl+Shift+Space, where the Mac takes Ctrl+Space for its own).
mkdir -p /home/u/.config/fcitx5
cat > /home/u/.config/fcitx5/profile <<'CONF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=mozc

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=mozc
Layout=

[GroupOrder]
0=Default
CONF
cat > /home/u/.config/fcitx5/config <<'CONF'
[Hotkey/TriggerKeys]
0=Control+space
1=Control+Shift+space
2=Zenkaku_Hankaku
CONF
. /t/session.sh
# fcitx5 speaks input-method-v2 to Hyprland and wants the session bus.
su u -c "$ENVS fcitx5 -d --replace > /tmp/fcitx5.log 2>&1"
# The desktop, over VNC (wayvnc speaks to Hyprland's screencopy and virtual
# input protocols) and through noVNC for a browser.
su u -c "$ENVS wayvnc 0.0.0.0 5900 > /tmp/wayvnc.log 2>&1 &"
websockify --web /usr/share/novnc 6080 localhost:5900 > /tmp/novnc.log 2>&1 &
# The daemon, launched before the bus existed, retried on it here.
pgrep -x notifyd >/dev/null || su u -c "$ENVS /tmp/notifyd > /tmp/notifyd.log 2>&1 &"
sleep 1.5
su u -c "$ENVS notify-send 'almide-shell' 'Alt+Space: launcher · Alt+Enter: terminal · Alt+↑/↓/M: volume · Alt+N: a notification · Alt+T: ceangal · Ctrl+Shift+Space: 日本語入力'"
echo "ready: http://localhost:6080/vnc.html?autoconnect=1&resize=scale  (or a VNC viewer on localhost:5900)"
tail -f /dev/null
