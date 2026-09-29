# Show the kernel version (what `uname -r` prints) on the right side of the bar.
t=$(bar_text); echo "$t"
k=$(uname -r | cut -d- -f1)
echo "$t" | grep -q "$k" && pass "$k" || fail "no '$k'"
