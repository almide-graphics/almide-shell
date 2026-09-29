# Show how many windows each workspace has after its number, like '3 (2)'.
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq '1 ?\( ?1 ?\)' && echo "$t" | grep -Eq '3 ?\( ?2 ?\)' && pass || fail
