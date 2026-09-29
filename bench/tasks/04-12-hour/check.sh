# Show the time in 12-hour format with AM or PM, like 3:07 PM.
t=$(bar_text); echo "$t"
want=$(TZ=Asia/Tokyo date +%p)
h=$(echo "$t" | grep -Eo '[0-9]{1,2}:[0-9]{2} ?(AM|PM)' | head -1)
[ -n "$h" ] || fail "no 12-hour time"
hour=${h%%:*}; [ "$hour" -ge 1 ] && [ "$hour" -le 12 ] || fail "hour $hour"
echo "$h" | grep -q "$want" && pass "$h" || fail "$h, expected $want"
