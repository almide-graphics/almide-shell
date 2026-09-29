# Make the bar 40 pixels tall.
bar_geom || fail "no bar"
[ "$BH" -eq 40 ] && pass "40 high" || fail "$BH high"
