# Sourced inside the container: build the shell's programs from the checkout
# at /shell (against the snaidhm checkout at /snaidhm, and ceangal's at
# /ceangal when mounted) and snaidhm's demo
# window and virtual pointer, into /tmp; and a few applications for the
# launcher to find.
ALMIDE=/almide/build/release/almide
mkdir -p /w && cd /shell && tar --exclude=./target -cf - . | (cd /w && tar -xf -)
# snaidhm from the checkout mounted at /snaidhm, not from its remote.
mkdir -p /snaidhm-copy && cd /snaidhm && tar --exclude=./target -cf - . | (cd /snaidhm-copy && tar -xf -)
sed -i 's|^snaidhm = .*|snaidhm = { path = "/snaidhm-copy" }|' /w/almide.toml
# ceangal (the launcher's UI) from the checkout mounted at /ceangal when there
# is one, on the same snaidhm; else from its remote.
if [ -d /ceangal ]; then
  mkdir -p /ceangal-copy && (cd /ceangal && tar --exclude=./target -cf - . | (cd /ceangal-copy && tar -xf -))
  sed -i 's|^snaidhm = .*|snaidhm = { path = "/snaidhm-copy" }|' /ceangal-copy/almide.toml
  rm -f /ceangal-copy/almide.lock
  sed -i 's|^ceangal = .*|ceangal = { path = "/ceangal-copy" }|' /w/almide.toml
  chown -R u /ceangal-copy
fi
rm -f /w/almide.lock
chown -R u /w /snaidhm-copy
cd /w
$ALMIDE build --release main.almd -o /tmp/bar 2>&1 | tail -1
$ALMIDE build --release notifyd.almd -o /tmp/notifyd 2>&1 | tail -1
$ALMIDE build --release launcher.almd -o /tmp/launcher 2>&1 | tail -1
$ALMIDE build --release osd.almd -o /tmp/osd 2>&1 | tail -1
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
