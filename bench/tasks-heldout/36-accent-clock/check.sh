# Draw the clock's text in the accent colour (#7aa2f7).
bar_png || fail "no bar"
mid=$((BW * SCALE / 2))
n=$(count_colour 7aa2f7 $((mid - 200)) $((mid + 200))); echo "accent pixels in the middle: $n"
[ "$n" -gt 150 ] && pass || fail
