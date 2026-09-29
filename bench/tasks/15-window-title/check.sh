# Show the title of the focused window on the left side of the bar, after the workspaces.
as_u hyprctl dispatch workspace 1 >/dev/null; sleep 1.5
t=$(bar_text); echo "$t"
echo "$t" | grep -q 'notes-editor' || fail "no 'notes-editor' on workspace 1"
as_u hyprctl dispatch workspace 3 >/dev/null; sleep 1.5
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq 'draft-[ab]' && ! echo "$t" | grep -q 'notes-editor' && pass || fail "title not updated on workspace 3"
