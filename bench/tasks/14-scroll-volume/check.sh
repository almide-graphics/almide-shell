# Scrolling over the volume should change it by 5% per step: scrolling up raises it, scrolling down lowers it.
bar_words
vx=$(word_x '^vol$'); [ -n "$vx" ] || fail "no volume on the bar"
scroll $((BX + vx / SCALE + 12)) $((BY + BH / 2)) -1; sleep 1
v=$(volume); echo "$v"; echo "$v" | grep -q '0.47' || fail "not 0.47 after one step up"
scroll $((BX + vx / SCALE + 12)) $((BY + BH / 2)) 1; sleep 0.5
scroll $((BX + vx / SCALE + 12)) $((BY + BH / 2)) 1; sleep 1
v=$(volume); echo "$v"; echo "$v" | grep -q '0.37' && pass || fail "not 0.37 after two steps down"
