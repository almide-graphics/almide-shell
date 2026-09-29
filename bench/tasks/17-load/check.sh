# Add the 1-minute load average from /proc/loadavg to the right side of the bar, like 'load 0.42'.
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq 'load ?[0-9]+\.[0-9]{2}' && pass || fail
