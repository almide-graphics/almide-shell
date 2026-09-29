# Show the computer's hostname at the right end of the bar.
bar_words
x=$(word_x "^$(hostname)\$"); [ -n "$x" ] || fail "no '$(hostname)'"
[ "$x" -gt $((BW * SCALE * 2 / 3)) ] && pass "at $x" || fail "at $x, not the right end"
