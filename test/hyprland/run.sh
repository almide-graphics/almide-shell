#!/bin/bash
# Run the bar on a real Hyprland in Docker and save screenshots.
#
#   ALMIDE_SRC=~/src/almide [SCALE=2] test/hyprland/run.sh [OUT_DIR]
#
# Hyprland wants a DRM device. The container gets the host's vkms (a virtual
# KMS display, rendered by Mesa in software), so the Docker host must have it:
# on macOS with colima, use a profile of its own so the default VM is left
# alone —
#   colima start -p hypr
#   colima ssh -p hypr -- 'sudo apt-get install -y linux-image-generic linux-modules-extra-$(uname -r)'
#   (after installing a kernel that ships vkms: colima restart -p hypr)
#   colima ssh -p hypr -- sudo modprobe vkms
# and DOCKER_CONTEXT=colima-hypr. SNAIDHM_SRC is the snaidhm checkout the bar
# is built against (default: ../snaidhm).
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
OUT=${1:-$ROOT/capture}
SNAIDHM_SRC=${SNAIDHM_SRC:-$(cd "$ROOT/../snaidhm" && pwd)}
: "${ALMIDE_SRC:?set ALMIDE_SRC to an almide checkout}"
docker build -q -t almide-shell-hypr "$HERE" >/dev/null
docker volume create almide-build >/dev/null
# Name servers of our own: colima's DNS forwarder stops answering after the
# VM restarts, and the build fetches git dependencies.
DNS="--dns 1.1.1.1"
docker run --rm $DNS -v "$ALMIDE_SRC":/src:ro -v almide-build:/almide almide-shell-hypr bash -c '
  mkdir -p /almide/src && cd /src && tar --exclude=./target -cf - . | (cd /almide/src && tar -xf -) &&
  cd /almide/src && CARGO_TARGET_DIR=/almide/build cargo build --release 2>&1 | tail -1'
mkdir -p "$OUT"
docker run --rm $DNS --privileged -e SCALE="${SCALE:-2}" -v /dev/dri:/dev/dri -v /run/udev:/run/udev:ro \
  -v "$ROOT":/shell:ro -v "$SNAIDHM_SRC":/snaidhm:ro -v almide-build:/almide -v "$OUT":/out \
  -v "$HERE/capture.sh":/capture.sh:ro almide-shell-hypr /capture.sh /out/bar.png
echo "saved $OUT/before-click.png and $OUT/bar.png"
