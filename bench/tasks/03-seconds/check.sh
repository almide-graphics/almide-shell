# Show seconds in the clock.
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq '[0-9]{2}:[0-9]{2}:[0-9]{2}' && pass || fail "no HH:MM:SS"
