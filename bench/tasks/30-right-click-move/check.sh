# Right-clicking a workspace button should move the focused window to that workspace.
bar_geom || fail "no bar"
rclick 22 $((BY + BH / 2)); sleep 1
n1=$(as_u hyprctl workspaces -j | jq '.[] | select(.id == 1) | .windows')
n3=$(as_u hyprctl workspaces -j | jq '.[] | select(.id == 3) | .windows')
echo "ws1 $n1 ws3 $n3"
[ "$n1" = 2 ] && [ "$n3" = 1 ] && pass || fail
