# Clicking the clock should switch to workspace 1.
bar_words
cx=$(word_x '^[0-9]{1,2}:[0-9]{2}$'); [ -n "$cx" ] || fail "no clock on the bar"
click $((BX + cx / SCALE + 10)) $((BY + BH / 2)); sleep 1
w=$(active_ws); [ "$w" = 1 ] && pass || fail "on workspace $w"
