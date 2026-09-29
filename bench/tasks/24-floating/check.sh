# Make the bar float: leave an 8 pixel gap between it and the top, left and right edges of the screen.
bar_geom || fail "no bar"
echo "$BX $BY $BW $BH"
[ "$BX" -eq 8 ] && [ "$BY" -eq 8 ] && [ "$BW" -eq $((LW - 16)) ] && pass || fail
