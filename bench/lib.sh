# Sourced by verify.sh: what a task's check.sh may use. Everything observes
# the running session from outside — the compositor's view of the bar's
# surface, the screen's pixels, text read off them, the state the bar drives
# — so one check judges both languages' bars alike. Coordinates: X, Y are
# surface units (the bar's own), PX, PY screen pixels (units x $SCALE).

as_u() { su u -c "$ENVS $*"; }

# The bar's surface as the compositor places it: sets BX BY BW BH (units).
# The bar is the widest layer surface the shell's process has.
bar_geom() {
  local g
  g=$(as_u hyprctl layers -j | jq -r --argjson pid "$SHELL_PID" '
    [.[] | .levels[] | .[] | select(.pid == $pid)] | max_by(.w) | "\(.x) \(.y) \(.w) \(.h)"')
  read BX BY BW BH <<< "$g"
  [ -n "${BH:-}" ] && [ "$BH" != "null" ]
}

# The screen, and the bar's part of it, as PNGs.
shot() { as_u grim /tmp/screen.png; }
bar_png() {
  shot && bar_geom || return 1
  convert /tmp/screen.png -crop "$((BW * SCALE))x$((BH * SCALE))+$((BX * SCALE))+$((BY * SCALE))" +repage /tmp/bar.png
}

# Wait until the bar has stopped changing — its first frames may be drawn
# before the output's scale reached it, or mid-layout — up to 10 s: two
# captures a second apart that match.
settle() {
  local prev=""
  for i in $(seq 10); do
    bar_png || { sleep 1; continue; }
    local sum=$(md5sum < /tmp/bar.png)
    [ "$sum" = "$prev" ] && return 0
    prev=$sum
    sleep 1
  done
}

# The bar's text, read with OCR (on a light-on-dark bar: negated, enlarged).
ocr_prep() { convert /tmp/bar.png -negate -resize 200% /tmp/bar-ocr.png; }
# Read several ways — negated for light text on the dark bar, as is for dark
# text on a light highlight, enlarged 2x and 3x, as one line and as a block —
# and every reading returned, " | " between: one misreading (a dropped word,
# "422%" for "42%") does not decide a check. OCR may drop the space between
# words, so checks match spaces as optional (" ?").
bar_text() {
  bar_png && ocr_prep || return 1
  convert /tmp/bar.png -resize 200% /tmp/bar-plain.png
  convert /tmp/bar.png -negate -resize 300% /tmp/bar-ocr3.png
  convert /tmp/bar.png -colorspace gray -negate -resize 300% -threshold 55% /tmp/bar-bw.png
  {
    tesseract /tmp/bar-ocr.png - --psm 7; echo " | "
    tesseract /tmp/bar-plain.png - --psm 7; echo " | "
    tesseract /tmp/bar-ocr3.png - --psm 6; echo " | "
    tesseract /tmp/bar-bw.png - --psm 7
  } 2>/dev/null | tr '\n' ' '
}

# Words with where they start: "LEFT_PX WORD" per line, in bar pixels.
bar_words() {
  bar_png && ocr_prep && tesseract /tmp/bar-ocr.png - --psm 7 tsv 2>/dev/null |
    awk -F'\t' 'NR > 1 && $12 != "" && $11 > 30 { print int($7 / 2), $12 }'
}
# The bar-pixel x where WORD (a regex) starts, or nothing.
word_x() { bar_words | awk -v re="$1" '$2 ~ re { print $1; exit }'; }

# Colour of screen pixel (PX, PY), as rrggbb.
pixel() { convert /tmp/screen.png -crop "1x1+$1+$2" -depth 8 txt:- | tail -1 | grep -o '#[0-9A-Fa-f]\{6\}' | tr -d '#' | tr 'A-F' 'a-f'; }
# How many pixels of the bar are colour rrggbb (within a little, for
# anti-aliasing), optionally only in bar-pixel columns [X0, X1).
count_colour() {
  local fuzz=${FUZZ:-6%}
  local region=/tmp/bar.png
  if [ $# -ge 3 ]; then convert /tmp/bar.png -crop "$(( $3 - $2 ))x10000+$2+0" +repage /tmp/bar-part.png; region=/tmp/bar-part.png; fi
  convert "$region" -fuzz "$fuzz" -fill white -opaque "#$1" -fill black +opaque white -format '%[fx:int(mean*w*h+0.5)]' info:
}

# The pointer, driven through the compositor: click / right-click / wheel at
# (X, Y) in layout units.
click()  { as_u /tmp/drive extent $LW $LH move $1 $2 sleep 150 click sleep 300 >/dev/null; }
rclick() { as_u /tmp/drive extent $LW $LH move $1 $2 sleep 150 rclick sleep 300 >/dev/null; }
scroll() { as_u /tmp/drive extent $LW $LH move $1 $2 sleep 150 scroll $3 sleep 300 >/dev/null; }

active_ws() { as_u hyprctl activeworkspace -j | jq .id; }
volume()    { as_u wpctl get-volume @DEFAULT_AUDIO_SINK@; }

pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*"; exit 1; }
