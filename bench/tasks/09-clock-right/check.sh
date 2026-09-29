# Move the clock to the right side of the bar, just before the volume.
bar_words
# The clock's first word (the weekday) must be past the middle.
cx=$(word_x '^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)$'); vx=$(word_x '^vol$')
[ -n "$cx" ] && [ -n "$vx" ] || fail "clock '$cx' volume '$vx'"
[ "$cx" -gt $((BW * SCALE / 2)) ] && [ "$cx" -lt "$vx" ] && pass "clock $cx vol $vx" || fail "clock $cx vol $vx"
