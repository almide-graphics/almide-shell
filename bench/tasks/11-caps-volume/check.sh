# Show the volume in capitals, like 'VOL 42%'.
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq 'VOL ?42%' && pass || fail
