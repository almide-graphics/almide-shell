# Make the bar's background pure black (#000000).
bar_png || fail "no bar"
total=$((BW * BH * SCALE * SCALE))
# Exact colours: text edges blended over black pass through dark greys near
# the old background's.
black=$(FUZZ=1% count_colour 000000); old=$(FUZZ=1% count_colour 1a1b26)
echo "black $black old $old of $total"
[ $((black * 2)) -gt "$total" ] && [ "$old" -lt $((total / 50)) ] && pass || fail
