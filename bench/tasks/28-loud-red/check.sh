# Show the volume in red (#f7768e) when it is above 80%.
bar_png || fail "no bar"
x0=$((BW * SCALE * 2 / 3))
red=$(count_colour f7768e $x0 $((BW * SCALE))); echo "red at 42%: $red"
[ "$red" -lt 20 ] || fail "red at 42%"
as_u wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.9; sleep 7
bar_png; red=$(count_colour f7768e $x0 $((BW * SCALE))); echo "red at 90%: $red"
[ "$red" -gt 50 ] && pass || fail
