# Add memory usage to the right side of the bar, like 'mem 37%', where used memory is MemTotal minus MemAvailable from /proc/meminfo.
t=$(bar_text); echo "$t"
got=$(echo "$t" | grep -Eo 'mem ?[0-9]+%' | grep -Eo '[0-9]+')
[ -n "$got" ] || fail "no 'mem N%'"
want=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d", (t-a)*100/t + 0.5}' /proc/meminfo)
d=$((got - want)); [ ${d#-} -le 3 ] && pass "$got% (actual $want%)" || fail "$got%, actual $want%"
