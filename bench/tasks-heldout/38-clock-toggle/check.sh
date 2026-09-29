# Clicking the clock should switch it between showing the time and showing the date (like 'Sep 29'); clicking again switches back.
bar_words
cx=$(word_x '^[0-9]{1,2}:[0-9]{2}$'); [ -n "$cx" ] || fail "no time on the bar"
click $((BX + cx / SCALE + 10)) $((BY + BH / 2)); sleep 1
t=$(bar_text); echo "after one click: $t"
d=$(TZ=Asia/Tokyo date '+%b %-d')
echo "$t" | grep -Eq "${d% *} ?0?${d#* }" || fail "no date '$d' after a click"
echo "$t" | grep -Eq '[0-9]{1,2}:[0-9]{2}' && fail "the time is still shown after a click"
bar_words
x=$(word_x "^${d% *}\$"); [ -n "$x" ] || fail "cannot find the date to click"
click $((BX + x / SCALE + 10)) $((BY + BH / 2)); sleep 1
t=$(bar_text); echo "after two clicks: $t"
echo "$t" | grep -Eq '[0-9]{1,2}:[0-9]{2}' && pass || fail "the time did not come back"
