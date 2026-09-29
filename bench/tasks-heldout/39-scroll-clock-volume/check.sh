# Scrolling over the clock should change the volume by 5% per step (up raises it).
bar_words
cx=$(word_x '^[0-9]{1,2}:[0-9]{2}$'); [ -n "$cx" ] || fail "no clock on the bar"
scroll $((BX + cx / SCALE + 10)) $((BY + BH / 2)) -1; sleep 1
v=$(volume); echo "$v"; echo "$v" | grep -q '0.47' && pass || fail "not 0.47 after one step up"
