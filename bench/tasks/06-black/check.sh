# Make the bar's background pure black (#000000).
bar_png || fail "no bar"
total=$((BW * BH * SCALE * SCALE))
black=$(count_colour 000000); old=$(count_colour 1a1b26)
echo "black $black old $old of $total"
[ $((black * 2)) -gt "$total" ] && [ "$old" -lt $((total / 50)) ] && pass || fail
