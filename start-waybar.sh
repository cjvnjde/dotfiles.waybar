#!/bin/bash

DE="${WAYBAR_DE:-sway}" 
CONFIG_FILE="$HOME/.config/waybar/${DE}/config.jsonc"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Warning: Configuration file not found for $DE. Using sway."
  CONFIG_FILE="$HOME/.config/waybar/sway/config.jsonc"
fi

waybar -c $CONFIG_FILE
