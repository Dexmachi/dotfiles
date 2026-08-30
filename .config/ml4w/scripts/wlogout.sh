res_w=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
res_h=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .height')
w_margin=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | (.height * 0.27 / .scale)' | awk '{printf "%.0f\n", $1}')
wlogout -b 5 -T $w_margin -B $w_margin
