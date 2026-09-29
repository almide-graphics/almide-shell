# Next to the local time, also show the time in UTC, like 'UTC 03:00'.
t=$(bar_text); echo "$t"
got=$(echo "$t" | grep -Eo 'UTC ?[0-9]{2}:[0-9]{2}' | head -1 | tr -d ' '); [ -n "$got" ] || fail "no 'UTC HH:MM'"
now=$(( $(date -u +%s) / 60 )); hh=${got:3:2}; mm=${got:6:2}
day=$(( now % 1440 )); shown=$(( 10#$hh * 60 + 10#$mm ))
d=$(( day - shown )); [ ${d#-} -le 1 ] && pass "$got" || fail "$got, now $(date -u +%H:%M)"
