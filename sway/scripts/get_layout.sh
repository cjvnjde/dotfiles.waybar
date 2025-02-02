#!/bin/sh

layout=$(swaymsg -t get_inputs | jq -r '.[] | select(.type == "keyboard") | .xkb_active_layout_name' | head -n 1)

if [[ $layout == *,* ]]; then
  layout=$(echo "$layout" | cut -d ',' -f 1)
fi

echo "$layout"
