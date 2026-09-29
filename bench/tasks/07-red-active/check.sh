# Highlight the active workspace in red (#f7768e) instead of blue.
bar_png || fail "no bar"
w=$((BW * SCALE / 3))
red=$(count_colour f7768e 0 $w); blue=$(count_colour 7aa2f7 0 $w)
echo "red $red blue $blue"
[ "$red" -gt 200 ] && [ "$blue" -lt 50 ] && pass || fail
