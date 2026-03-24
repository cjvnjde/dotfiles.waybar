#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

resolve_script_path() {
  local path="$1"

  if command -v realpath >/dev/null 2>&1; then
    realpath "$path" 2>/dev/null && return
  fi

  if command -v readlink >/dev/null 2>&1; then
    readlink -f "$path" 2>/dev/null && return
  fi

  local dir
  dir="$(cd -P "$(dirname "$path")" && pwd)"
  printf '%s/%s\n' "$dir" "$(basename "$path")"
}

SCRIPT_PATH="$(resolve_script_path "${BASH_SOURCE[0]}")"
MODULE_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)"
ROOT_DIR="$(cd "$MODULE_DIR/.." && pwd -P)"
DEST_DIR="$HOME/.config/waybar"

source "$ROOT_DIR/setup/lib.sh"

TARGET="$(read_value_file "$MODULE_DIR/target" "sway")"

validate_target() {
  case "$TARGET" in
    sway|hyprland|niri) ;;
    *)
      error "Unknown waybar target: $TARGET"
      error "Expected one of: sway, hyprland, niri"
      exit 1
      ;;
  esac
}

enable() {
  validate_target
  unlink_path "$MODULE_DIR" "$DEST_DIR"
  ensure_directory "$DEST_DIR"

  link_path "$MODULE_DIR/style.css" "$DEST_DIR/style.css"
  link_path "$MODULE_DIR/scripts" "$DEST_DIR/scripts"
  link_path "$MODULE_DIR/sway" "$DEST_DIR/sway"
  link_path "$MODULE_DIR/hyprland" "$DEST_DIR/hyprland"
  link_path "$MODULE_DIR/niri" "$DEST_DIR/niri"

  if ! is_link_to "$MODULE_DIR/$TARGET/config.jsonc" "$DEST_DIR/config.jsonc"; then
    unlink_path "$MODULE_DIR/sway/config.jsonc" "$DEST_DIR/config.jsonc"
    unlink_path "$MODULE_DIR/hyprland/config.jsonc" "$DEST_DIR/config.jsonc"
    unlink_path "$MODULE_DIR/niri/config.jsonc" "$DEST_DIR/config.jsonc"
  fi

  link_path "$MODULE_DIR/$TARGET/config.jsonc" "$DEST_DIR/config.jsonc"
  info "Waybar target = $TARGET"
}

disable() {
  unlink_path "$MODULE_DIR" "$DEST_DIR"
  unlink_path "$MODULE_DIR/style.css" "$DEST_DIR/style.css"
  unlink_path "$MODULE_DIR/scripts" "$DEST_DIR/scripts"
  unlink_path "$MODULE_DIR/sway" "$DEST_DIR/sway"
  unlink_path "$MODULE_DIR/hyprland" "$DEST_DIR/hyprland"
  unlink_path "$MODULE_DIR/niri" "$DEST_DIR/niri"
  unlink_path "$MODULE_DIR/sway/config.jsonc" "$DEST_DIR/config.jsonc"
  unlink_path "$MODULE_DIR/hyprland/config.jsonc" "$DEST_DIR/config.jsonc"
  unlink_path "$MODULE_DIR/niri/config.jsonc" "$DEST_DIR/config.jsonc"
  rmdir_if_empty "$DEST_DIR"
}

case "${1:-}" in
  enable)
    enable
    ;;
  disable)
    disable
    ;;
  *)
    error "Usage: bash $MODULE_DIR/setup.sh <enable|disable>"
    exit 1
    ;;
esac
