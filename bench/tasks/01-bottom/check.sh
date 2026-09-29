# Move the bar to the bottom of the screen.
bar_geom || fail "no bar"
[ "$BH" -eq 30 ] || fail "height $BH"
[ $((BY + BH)) -eq "$LH" ] && pass "at y=$BY" || fail "at y=$BY (screen $LH high)"
