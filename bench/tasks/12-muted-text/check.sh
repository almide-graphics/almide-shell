# When the sound is muted, show just 'MUTED' where the volume normally is.
t=$(bar_text); echo "unmuted: $t"
echo "$t" | grep -Eq '42%' || fail "the volume is not shown unmuted"
as_u wpctl set-mute @DEFAULT_AUDIO_SINK@ 1; sleep 7
t=$(bar_text); echo "muted: $t"
echo "$t" | grep -q 'MUTED' && ! echo "$t" | grep -q 'vol' && pass || fail
