# Show the number of the active workspace on the right side of the bar, like 'ws 3'.
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq 'ws ?3' || fail "no 'ws 3'"
as_u hyprctl dispatch workspace 1 >/dev/null; sleep 1.5
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq 'ws ?1' && pass || fail "not 'ws 1' after switching"
