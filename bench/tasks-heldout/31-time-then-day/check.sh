# Change the clock to show the time first and then the weekday, like '12:34 Tue', and nothing else.
t=$(bar_text); echo "$t"
echo "$t" | grep -Eq '[0-9]{1,2}:[0-9]{2} ?(Mon|Tue|Wed|Thu|Fri|Sat|Sun)' || fail "no 'HH:MM Day'"
echo "$t" | grep -Eq '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)' && fail "the month is still shown" || pass
