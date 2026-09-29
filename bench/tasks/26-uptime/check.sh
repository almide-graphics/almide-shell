# Add the system uptime to the right side of the bar, like 'up 5m', or 'up 2h 5m' after an hour.
t=$(bar_text); echo "$t"
got=$(echo "$t" | grep -Eo 'up ?([0-9]+h ?)?[0-9]+m' | head -1); [ -n "$got" ] || fail "no uptime"
h=$(echo "$got" | grep -Eo '[0-9]+h' | tr -d h); m=$(echo "$got" | grep -Eo '[0-9]+m' | tr -d m)
mins=$(( ${h:-0} * 60 + m )); want=$(awk '{print int($1 / 60)}' /proc/uptime)
d=$((mins - want)); [ ${d#-} -le 2 ] && pass "$got" || fail "$got, uptime ${want}m"
