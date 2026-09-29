# Add the text 'hyprland' in the dim colour (#565f89) at the far right of the bar.
bar_words
x=$(word_x '^hyp[a-z]{1,2}and$'); [ -n "$x" ] || fail "no 'hyprland'"
[ "$x" -gt $((BW * SCALE * 2 / 3)) ] || fail "at $x, not the far right"
bar_png; n=$(count_colour 565f89 $x $((BW * SCALE))); echo "dim pixels: $n"
[ "$n" -gt 60 ] && pass || fail "not in the dim colour"
