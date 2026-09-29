# Make the bar's text bigger: 18 pixels instead of 14.
bar_png || fail "no bar"
# The clock's glyphs: rows of text-coloured pixels in the middle of the bar.
mid=$((BW * SCALE / 2))
convert /tmp/bar.png -crop "300x$((BH * SCALE))+$((mid - 150))+0" +repage -fuzz 25% -fill white -opaque "#c0caf5" -fill black +opaque white -trim -format '%h' info: > /tmp/h 2>/dev/null
h=$(cat /tmp/h); echo "text height ${h}px"
[ "$h" -ge 32 ] && pass || fail
