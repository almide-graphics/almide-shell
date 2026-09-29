# Remove the volume from the bar.
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq '[0-9]{1,2}:[0-9]{2}' || fail "the clock went too"
echo "$t" | grep -qi 'vol' && fail "volume still shown" || pass
