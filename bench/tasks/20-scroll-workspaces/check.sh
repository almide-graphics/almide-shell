# Scrolling over the workspaces should switch workspace: scrolling down goes to the next number, scrolling up to the previous one.
bar_geom || fail "no bar"
scroll 24 $((BY + BH / 2)) 1; sleep 1
w=$(active_ws); [ "$w" = 4 ] || fail "on $w after scrolling down from 3"
scroll 24 $((BY + BH / 2)) -1; sleep 1
w=$(active_ws); [ "$w" = 3 ] && pass || fail "on $w after scrolling back up"
