#!/bin/sh

# Font and Gruvbox-style colors
BAR_FONT="Monospace-10"
FG="#ebdbb2"
BG="#1d2021"
HL="#fabd2f"

# Bar dimensions
BAR_HEIGHT=24
Y_OFFSET=10
SIDE_MARGIN=20

# Calculate screen width, bar width, and X offset
SCREEN_WIDTH=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f1)
BAR_WIDTH=$((SCREEN_WIDTH - SIDE_MARGIN * 2))
X_OFFSET=$SIDE_MARGIN

# PulseAudio volume function
get_volume() {
    sink=$(pactl get-default-sink)
    vol=$(pactl get-sink-volume "$sink" | awk -F '/' 'NR==1{gsub(/ /, "", $2); print $2}')
    muted=$(pactl get-sink-mute "$sink" | awk '{print $2}')
    icon=""
    [ "$muted" = "yes" ] && icon=""
    echo "${icon} ${vol}"
}

while :; do
    # Workspaces
    workspaces=""
    current_ws=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')
    for i in $(seq 0 8); do
        num=$((i + 1))
        if [ "$i" = "$current_ws" ]; then
            workspaces="${workspaces}%{F$HL}[${num}]%{F-} "
        else
            workspaces="${workspaces}[${num}] "
        fi
    done

    # Date/time (Philippine time)
    datetime=$(env TZ='Asia/Manila' date "+%a %d %b %I:%M %p")

    # Volume
    volume=$(get_volume)
    volume_block="%{A1:pactl set-sink-mute @DEFAULT_SINK@ toggle:}%{A4:pactl set-sink-volume @DEFAULT_SINK@ +5%:}%{A5:pactl set-sink-volume @DEFAULT_SINK@ -5:}$volume%{A}%{A}%{A}"

    # Player info (click to play/pause)
    player_info=$(/home/env/hehe/shfiles/player.sh)
    player_block="%{A1:playerctl play-pause:}$player_info%{A}"

    # Compose right side: volume + player + time, separated by 2 spaces
    right_side="$volume_block  $player_block  $datetime"

    echo "%{l}$workspaces%{r}$right_side"

    sleep 1
done | lemonbar -p -g "${BAR_WIDTH}x${BAR_HEIGHT}+${X_OFFSET}+${Y_OFFSET}" \
    -f "$BAR_FONT" -B "$BG" -F "$FG" | sh
