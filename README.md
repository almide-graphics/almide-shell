# almide-shell

A desktop shell for Hyprland — bar, launcher, notifications, on-screen
displays — written in [Almide](https://github.com/almide/almide), with nothing
under it but the language runtime: the Wayland protocol, the layer-shell
surfaces, Hyprland's IPC, the fonts and the pixels are all Almide
([snaidhm](https://github.com/almide-graphics/snaidhm) supplies the Wayland
client, the CPU canvas and the font reader).

## The goal

**Show that you can ask an AI to change your desktop, and it doesn't break.**

[Omarchy](https://github.com/basecamp/omarchy) is Hyprland plus a shell
written in QML (Quickshell). This project replaces that shell layer with
Almide, and then measures what matters: when a user asks an LLM "add the
weather to the bar" or "move notifications to the top right", how often the
change works on the first try — against the same requests made of the QML
shell. Almide's mission is to be the language LLMs write most accurately;
a desktop shell is code people already hand to LLMs every day.

| Milestone | Done when |
|---|---|
| **M1 bar** | A layer-shell bar on Hyprland shows workspaces (Hyprland IPC), a clock, battery and volume; no Rust but the language runtime |
| **M2 shell** | Launcher, notification daemon (D-Bus in Almide), volume/brightness OSD |
| **M3 daily use** | A week as the only shell: 0 crashes, idle CPU ~0 %, start under 100 ms |
| **M4 evidence** | 30 "customize the shell" tasks in [almide-dojo](https://github.com/almide/almide-dojo): modification survival rate, Almide vs QML, same model |

Not in scope: the compositor (Hyprland stays), GPU rendering.

## Try it

Without Hyprland on your machine: `test/hyprland/try.sh` runs Hyprland in
Docker with the bar, notifications, OSD and launcher, and shows its screen in a
browser at <http://localhost:6080/vnc.html?autoconnect=1&resize=scale>.
Alt+Space opens the launcher, Alt+Enter a terminal, Alt+↑/↓/M the volume,
Alt+N sends a notification, Alt+1..4 switches workspaces.

## Status: M1

`almide run main.almd` under Hyprland (or any compositor with wlr-layer-shell)
draws the bar across the top of the output:

- **Workspaces** from Hyprland's IPC; the active one highlighted; a click
  switches (the `dispatch` socket), and the bar follows Hyprland's event
  socket.
- **Clock** in local time — the time zone read from `/etc/localtime` or `$TZ`
  (TZif and POSIX rules, `src/tz.almd`; checked against Python's zoneinfo over
  18 zones from 1900 to 2100 by `test/tz_oracle.py`).
- **Volume** from PipeWire (`wpctl`), **battery** from sysfs.
- The binary links no Rust crate beyond the runtime (1.1 MB, no wgpu/winit).
- Idle: one `poll` over the Wayland and Hyprland sockets until the next thing
  is due — 1 clock tick of CPU in 20 s (0.05 %), 25 MB resident.

What it shows is `src/config.almd` — the file to edit, or to ask an AI to
edit:

```almide
let LEFT: List[Module] = [Workspaces]
let CENTER: List[Module] = [Clock("%a %b %d  %H:%M")]
let RIGHT: List[Module] = [Volume, Battery]
```

`test/hyprland/run.sh` runs it on a real Hyprland in Docker (vkms + Mesa's
software renderer): two windows on workspaces 1 and 3, a click on the bar's
"1", screenshots before and after, and the idle measurement.

## Status: M2 (in progress)

- **Notifications** — `notifyd.almd` owns `org.freedesktop.Notifications` on
  the session bus, over a D-Bus implementation written in Almide
  (`src/dbus.almd`: SASL EXTERNAL, the marshalling rules, messages both ways).
  `notify-send` and `gdbus` talk to it unchanged: Notify, CloseNotification
  (with the NotificationClosed signal), GetCapabilities, GetServerInformation.
  Cards stack at the top right, wrap text (Japanese included), expire, and
  close on a click.
- **Launcher** — `launcher.almd` (bind it: `bind = SUPER, SPACE, exec,
  launcher`): the installed applications from the XDG `.desktop` files
  (`src/apps.almd`), filtered as you type, Up/Down/Tab to pick, Enter starts
  it through Hyprland's `exec`, Escape closes. It sizes itself to the room the
  output has.
- **Any scale** — every surface draws at the output's scale, fractional ones
  included (`wp_fractional_scale_v1` + `wp_viewporter`), and stays sharp:
  the canvas draws in units, so no drawing code multiplies by the scale.
  `SCALE=1.6 test/hyprland/run.sh` checks it.
- **OSD** — `osd volume +5 | -5 | mute`, `osd brightness +5 | -5`, bound to
  the media keys (the lines are in `osd.almd`): the first run becomes the
  daemon, later ones hand their command over a Unix socket, so repeated
  presses update one panel. Volume through PipeWire's `wpctl`; brightness
  written to sysfs, or through logind's `SetBrightness` on the system bus
  where sysfs is not the user's to write.

## Next

- Volume and battery from events instead of reads every 5 and 30 s
  (PipeWire's protocol, UPower over D-Bus) — the last periodic wakes.
- Partial redraw (damage).
- The bar hears of a volume change only at its next 5-second read: events from PipeWire itself.
