# The bar should not reserve space: windows should extend to the top of the screen, underneath the bar.
bar_geom || fail "no bar"
y=$(as_u hyprctl activewindow -j | jq '.at[1]'); echo "window at y=$y"
[ "$y" -lt 20 ] && pass || fail
