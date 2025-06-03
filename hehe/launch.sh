#!/bin/bash

APP_DIRS=(
  "$HOME/.local/share/applications"
  "/usr/share/applications"
  "/var/lib/flatpak/exports/share/applications"
  "$HOME/.local/share/flatpak/exports/share/applications"
)

app_list=""

# Collect all apps
while IFS= read -r file; do
  if grep -q '^NoDisplay=true' "$file"; then
    continue
  fi

  name=$(grep -m1 '^Name=' "$file" | cut -d= -f2)
  desktop_id=$(basename "$file" .desktop)
  [ -z "$name" ] && name="$desktop_id"

  app_list+="$name|$desktop_id"$'\n'
done < <(find "${APP_DIRS[@]}" \( -type f -o -type l \) -name '*.desktop')

# Check if Spotify is missing and add manually if found flatpak app id
if ! echo "$app_list" | grep -q 'com.spotify.Client'; then
  # Check if flatpak app exists
  if flatpak info com.spotify.Client >/dev/null 2>&1; then
    app_list="[Spotify] Spotify|com.spotify.Client"$'\n'"$app_list"
  fi
fi

choice=$(echo "$app_list" | cut -d'|' -f1 | sort -u | dmenu -i -p "Launch:")
[ -z "$choice" ] && exit 0

desktop_id=$(echo "$app_list" | grep "^$choice|" | cut -d'|' -f2 | head -n1)

DBUS_ADDR=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u $USER dbus-daemon | head -n1)/environ 2>/dev/null | tr '\0' '\n' | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p')
[ -z "$DBUS_ADDR" ] && DBUS_ADDR=$DBUS_SESSION_BUS_ADDRESS

export DBUS_SESSION_BUS_ADDRESS=$DBUS_ADDR
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export PATH=$PATH:/var/lib/flatpak/exports/bin:~/.local/share/flatpak/exports/bin

if [[ "$desktop_id" == *.*.* ]]; then
  flatpak run "$desktop_id" &
else
  gtk-launch "$desktop_id" &
fi
