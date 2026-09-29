# Clicking the volume should mute or unmute the sound.
bar_words
vx=$(word_x '^vol$'); [ -n "$vx" ] || fail "no volume on the bar"
click $((BX + vx / SCALE + 12)) $((BY + BH / 2)); sleep 1
v=$(volume); echo "$v"; echo "$v" | grep -q MUTED || fail "not muted after a click"
click $((BX + vx / SCALE + 12)) $((BY + BH / 2)); sleep 1
v=$(volume); echo "$v"; echo "$v" | grep -q MUTED && fail "still muted after a second click" || pass
