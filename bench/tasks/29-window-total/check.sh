# Add the total number of open windows to the right side of the bar, like '3 windows'.
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq '3 ?windows' || fail "no '3 windows'"
as_u "foot -T shell-c sleep 600 >/dev/null 2>&1 &"; sleep 2
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq '4 ?windows' && pass || fail "not '4 windows' after opening one"
