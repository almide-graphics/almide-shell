#!/bin/bash
# Use the shell yourself, without Hyprland on this machine: Hyprland runs in
# Docker on the host's vkms (see run.sh for the host setup), with the bar,
# notifications, OSD and launcher, and its screen comes out in a browser.
#
#   ALMIDE_SRC=~/src/almide [SCALE=1] test/hyprland/try.sh
#   open "http://localhost:6080/vnc.html?autoconnect=1&resize=scale"
#
# Ctrl-C stops it.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
SNAIDHM_SRC=${SNAIDHM_SRC:-$(cd "$ROOT/../snaidhm" && pwd)}
docker build -q -t almide-shell-hypr "$HERE" >/dev/null
if [ -n "${ALMIDE_SRC:-}" ]; then
  docker volume create almide-build >/dev/null
  docker run --rm --dns 1.1.1.1 -v "$ALMIDE_SRC":/src:ro -v almide-build:/almide almide-shell-hypr bash -c '
    mkdir -p /almide/src && cd /src && tar --exclude=./target -cf - . | (cd /almide/src && tar -xf -) &&
    cd /almide/src && CARGO_TARGET_DIR=/almide/build cargo build --release 2>&1 | tail -1'
fi
docker run --rm -it --dns 1.1.1.1 --privileged -e SCALE="${SCALE:-1}" -p 6080:6080 -p 5900:5900 \
  -v /dev/dri:/dev/dri -v /run/udev:/run/udev:ro \
  -v "$ROOT":/shell:ro -v "$SNAIDHM_SRC":/snaidhm:ro -v almide-build:/almide -v "$HERE":/t:ro \
  almide-shell-hypr /t/desktop.sh
