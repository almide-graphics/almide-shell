# Add the disk usage of / to the right side of the bar, like 'disk 42%'.
t=$(bar_text); echo "$t"
got=$(echo "$t" | grep -Eo 'disk ?[0-9]+%' | head -1 | grep -Eo '[0-9]+'); [ -n "$got" ] || fail "no 'disk N%'"
want=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')
d=$((got - want)); [ ${d#-} -le 2 ] && pass "$got% (df: $want%)" || fail "$got%, df says $want%"
