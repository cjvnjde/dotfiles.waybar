#!/bin/bash

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t) DE="$2"; shift 2 ;;
    *) echo "Usage: $0 -t <desktop_environment>"; exit 1 ;;
  esac
done

DE="${DE:-default}"
CONFIG_FILE="$HOME/.config/waybar/${DE}/config.jsonc"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Warning: Configuration file not found for $DE. Using sway."
  CONFIG_FILE="$HOME/.config/waybar/sway/config.jsonc"
fi

waybar -c $CONFIG_FILE
