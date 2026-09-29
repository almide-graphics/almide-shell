# Label each workspace button with 'WS' before its number, like 'WS 3'.
# Focus an empty workspace first, so 1 and 3 are both plain buttons (the
# highlight's reversed text reads poorly).
as_u hyprctl dispatch workspace 5 >/dev/null; sleep 1.5; settle
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq 'WS ?1' && echo "$t" | grep -Eq 'WS ?3' && pass || fail
