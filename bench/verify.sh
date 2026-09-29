#!/bin/bash
# Inside the container: build the bar in /work (LANG almide or qml), start it
# on a fresh Hyprland session, run the task's setup and check, and print one
# result line:
#   RESULT build=ok|fail runs=ok|fail task=pass|fail alive=ok|fail
#   verify.sh LANG /task
set -u
LANG_=$1
TASK=$2
export SCALE=2
BUILD=fail RUNS=fail RESULT_TASK=fail ALIVE=fail
T0=$(date +%s)
stamp() { echo "t+$(( $(date +%s) - T0 ))s $1" >> /tmp/timing; }
mkdir -p /snaidhm-copy && (cd /snaidhm && tar --exclude=./target -cf - . | (cd /snaidhm-copy && tar -xf -))
mkdir -p /w && (cd /work && tar -cf - .) | (cd /w && tar -xf -)
ALMIDE=/almide/build/release/almide
# The virtual pointer, built once per snaidhm checkout.
DRIVE=/almide/drive-$(cd /snaidhm && git rev-parse --short HEAD 2>/dev/null || echo local)-$(md5sum /snaidhm/examples/wayland/drive.almd | cut -c1-8)
[ -x "$DRIVE" ] || (cd /snaidhm-copy && $ALMIDE build examples/wayland/drive.almd -o "$DRIVE" >/dev/null 2>&1)
cp "$DRIVE" /tmp/drive && chmod 755 /tmp/drive
if [ "$LANG_" = almide ]; then
  # The native build scratch (cargo target) survives between runs.
  mkdir -p /almide/tmp
  (cd /w && rm -f almide.lock && TMPDIR=/almide/tmp $ALMIDE build main.almd -o /tmp/bar > /tmp/build.log 2>&1) && BUILD=ok
else
  BUILD=ok
fi
stamp built
chown -R u /w /snaidhm-copy
# Errors come first: keep the head, where the root cause is.
echo "--- build"; head -120 /tmp/build.log 2>/dev/null
if [ $BUILD = ok ]; then
  . /t/session.sh
  . /bench/lib.sh
  stamp session
  # The desktop every task starts from: workspace 1 with one window titled
  # "notes-editor", workspace 3 with two, workspace 3 focused, volume 42 %.
  as_u "foot -T notes-editor sleep 600 >/dev/null 2>&1 &"; sleep 1
  as_u hyprctl dispatch workspace 3 >/dev/null
  as_u "foot -T draft-a sleep 600 >/dev/null 2>&1 &"; sleep 0.5
  as_u "foot -T draft-b sleep 600 >/dev/null 2>&1 &"; sleep 1
  if [ "$LANG_" = almide ]; then
    as_u "/tmp/bar > /tmp/shell.log 2>&1 & echo \$! > /tmp/shell.pid"
  else
    as_u "quickshell -p /w/shell.qml > /tmp/shell.log 2>&1 & echo \$! > /tmp/shell.pid"
  fi
  sleep 4
  stamp started
  SHELL_PID=$(cat /tmp/shell.pid)
  if kill -0 $SHELL_PID 2>/dev/null && bar_geom; then RUNS=ok; fi
  if [ $RUNS = ok ]; then
    [ -f $TASK/setup.sh ] && . $TASK/setup.sh
    echo "--- check"
    ( . $TASK/check.sh ) && RESULT_TASK=pass
    stamp checked
    sleep 1
    kill -0 $SHELL_PID 2>/dev/null && ALIVE=ok
  fi
  echo "--- shell log"; grep -v "^\s*$" /tmp/shell.log | tail -15
fi
echo "--- timing"; cat /tmp/timing 2>/dev/null
echo "RESULT build=$BUILD runs=$RUNS task=$RESULT_TASK alive=$ALIVE"
