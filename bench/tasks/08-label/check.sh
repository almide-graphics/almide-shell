# Add the text 'almide' at the far left of the bar, before the workspaces.
bar_words
x=$(word_x '^almide$')
[ -n "$x" ] || fail "no 'almide'"
[ "$x" -lt 60 ] && pass "at $x" || fail "at $x, not the far left"
