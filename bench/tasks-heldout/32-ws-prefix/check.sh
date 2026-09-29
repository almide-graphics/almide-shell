# Label each workspace button with 'WS' before its number, like 'WS 3'.
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq 'WS ?1' && echo "$t" | grep -Eq 'WS ?3' && pass || fail
