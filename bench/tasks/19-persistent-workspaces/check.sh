# Always show workspaces 1 to 5 on the bar, even the empty ones.
for n in 2 5 4; do
  bar_geom || fail "no bar"
  # Find workspace n's button by clicking along the left of the bar.
  found=0
  for x in $(seq 14 6 150); do
    click $x $((BY + BH / 2)); sleep 0.4
    if [ "$(active_ws)" = "$n" ]; then found=1; break; fi
  done
  [ $found = 1 ] || fail "no button switches to workspace $n"
done
pass "buttons for 2, 4 and 5"
