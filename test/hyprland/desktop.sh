#!/bin/bash
# Inside the container: the whole shell as a desktop to use — bar,
# notifications, OSD daemon, launcher and a terminal on keys — shown over VNC
# and, for a browser, noVNC on port 6080.
set -u
. /t/build.sh
# ceangal's todo app on its CPU host, when a ceangal checkout is mounted.
if [ -d /ceangal ]; then
  mkdir -p /ceangal-copy && (cd /ceangal && tar --exclude=./target -cf - . | (cd /ceangal-copy && tar -xf -))
  sed -i 's|^snaidhm = .*|snaidhm = { path = "/snaidhm-copy" }|' /ceangal-copy/almide.toml; rm -f /ceangal-copy/almide.lock
  (cd /ceangal-copy && $ALMIDE build examples/wayland/main.almd -o /tmp/ceangal 2>&1 | tail -1)
  chmod 755 /tmp/ceangal
fi
# Keys: ALT rather than SUPER, which a browser or VNC viewer keeps for itself.
mkdir -p /home/u/.config/hypr
cat > /home/u/.config/hypr/extra.conf <<'CONF'
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
. /t/session.sh
# The desktop, over VNC (wayvnc speaks to Hyprland's screencopy and virtual
# input protocols) and through noVNC for a browser.
su u -c "$ENVS wayvnc 0.0.0.0 5900 > /tmp/wayvnc.log 2>&1 &"
websockify --web /usr/share/novnc 6080 localhost:5900 > /tmp/novnc.log 2>&1 &
# The daemon, launched before the bus existed, retried on it here.
pgrep -x notifyd >/dev/null || su u -c "$ENVS /tmp/notifyd > /tmp/notifyd.log 2>&1 &"
sleep 1.5
su u -c "$ENVS notify-send 'almide-shell' 'Alt+Space: launcher · Alt+Enter: terminal · Alt+↑/↓/M: volume · Alt+N: a notification · Alt+T: ceangal'"
echo "ready: http://localhost:6080/vnc.html?autoconnect=1&resize=scale  (or a VNC viewer on localhost:5900)"
tail -f /dev/null
