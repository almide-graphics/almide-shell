# Show the date as YYYY-MM-DD (for example 2026-09-29) before the time.
t=$(bar_text); echo "$t"
d=$(TZ=Asia/Tokyo date +%Y-%m-%d)
echo "$t" | grep -Eq "$d +[0-9]{1,2}:[0-9]{2}" && pass "$d" || fail "no '$d' before the time"
