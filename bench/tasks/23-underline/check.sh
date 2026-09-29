# Draw a 2 pixel line in the accent colour (#7aa2f7) along the whole bottom edge of the bar.
bar_png || fail "no bar"
convert /tmp/bar.png -gravity south -crop "x$((2 * SCALE))+0+0" +repage /tmp/bar-bottom.png
n=$(convert /tmp/bar-bottom.png -fuzz 6% -fill white -opaque "#7aa2f7" -fill black +opaque white -format '%[fx:int(mean*w*h+0.5)]' info:)
all=$((BW * SCALE * 2 * SCALE)); echo "$n of $all"
[ $((n * 10)) -ge $((all * 9)) ] && pass || fail
