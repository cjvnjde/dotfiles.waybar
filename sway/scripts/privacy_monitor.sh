#!/bin/bash
#
# Privacy monitor for waybar - detects active microphone, camera, and screen sharing.
#
# Usage: privacy_monitor.sh [OPTIONS]
#   --mic         Monitor microphone usage
#   --cam         Monitor camera usage
#   --screen      Monitor screen sharing/recording
#   --all         Monitor all (default if no options given)
#
# Only active monitors are shown. The module is hidden when nothing is active.
# Active indicator colors:
#   Microphone:     orange
#   Camera:         red
#   Screen sharing: purple

monitor_mic=false
monitor_cam=false
monitor_screen=false

# Parse arguments
if [ $# -eq 0 ]; then
    monitor_mic=true
    monitor_cam=true
    monitor_screen=true
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --mic)    monitor_mic=true ;;
        --cam)    monitor_cam=true ;;
        --screen) monitor_screen=true ;;
        --all)    monitor_mic=true; monitor_cam=true; monitor_screen=true ;;
        *)        echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

# --- Detection functions ---

check_microphone() {
    # Check PulseAudio/PipeWire for active recording sources
    if command -v pactl >/dev/null 2>&1; then
        if pactl list source-outputs 2>/dev/null | grep -q "Source Output"; then
            echo true; return
        fi
    elif command -v pw-cli >/dev/null 2>&1; then
        if pw-cli list-objects 2>/dev/null | grep -A 20 "type:PipeWire:Interface:Node" \
            | grep -B 5 -A 15 "media.class.*Source" | grep -q "state.*running"; then
            echo true; return
        fi
    else
        # Fallback: check only capture devices in /proc/asound
        if [ -d "/proc/asound" ]; then
            for card in /proc/asound/card*; do
                for capture_device in "$card"/pcm*c/sub*/status; do
                    if [ -f "$capture_device" ]; then
                        status=$(cat "$capture_device" 2>/dev/null)
                        if [ "$status" = "RUNNING" ]; then
                            echo true; return
                        fi
                    fi
                done
            done
        fi
    fi
    echo false
}

check_camera() {
    if lsof /dev/video* 2>/dev/null | grep -q "video"; then
        echo true; return
    fi
    echo false
}

check_screen_sharing() {
    # Method 1: Check PipeWire for Video/Source nodes via pw-dump + python3.
    # When xdg-desktop-portal-wlr shares a screen, it creates a Video/Source node.
    # The node's mere existence means sharing is active (it is destroyed when stopped).
    if command -v pw-dump >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        if pw-dump 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for n in data:
    if n.get('type') == 'PipeWire:Interface:Node':
        props = n.get('info', {}).get('props', {})
        mc = props.get('media.class', '')
        name = props.get('node.name', '')
        if 'Video/Source' in mc and 'v4l2' not in name:
            sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
            echo true; return
        fi
    fi

    # Method 2: Check D-Bus for active xdg-desktop-portal-wlr sessions.
    # Session objects exist only while a ScreenCast session is active.
    if command -v busctl >/dev/null 2>&1; then
        if busctl --user tree org.freedesktop.impl.portal.desktop.wlr 2>/dev/null \
            | grep -q "/session/"; then
            echo true; return
        fi
    fi

    # Method 3: Fallback - check for standalone recording processes.
    for proc in wf-recorder wl-screenrec obs; do
        if pgrep -x "$proc" >/dev/null 2>&1; then
            echo true; return
        fi
    done

    echo false
}

# --- Build output ---

output_parts=()
tooltip_parts=()

if [ "$monitor_mic" = true ]; then
    mic_active=$(check_microphone)
    if [ "$mic_active" = true ]; then
        output_parts+=("<span color='orange'>●</span>")
        tooltip_parts+=("Microphone: ACTIVE")
    fi
fi

if [ "$monitor_cam" = true ]; then
    cam_active=$(check_camera)
    if [ "$cam_active" = true ]; then
        output_parts+=("<span color='red'>●</span>")
        tooltip_parts+=("Camera: ACTIVE")
    fi
fi

if [ "$monitor_screen" = true ]; then
    screen_active=$(check_screen_sharing)
    if [ "$screen_active" = true ]; then
        output_parts+=("<span color='purple'>●</span>")
        tooltip_parts+=("Screen sharing: ACTIVE")
    fi
fi

# Join parts
output=""
tooltip=""
for i in "${!output_parts[@]}"; do
    if [ $i -gt 0 ]; then
        output+=" "
        tooltip+=" | "
    fi
    output+="${output_parts[$i]}"
    tooltip+="${tooltip_parts[$i]}"
done

# Output empty class when nothing is active so waybar can hide the module
if [ ${#output_parts[@]} -eq 0 ]; then
    echo "{\"text\":\"\", \"tooltip\":\"All clear\", \"class\":\"inactive\"}"
else
    echo "{\"text\":\"$output\", \"tooltip\":\"$tooltip\", \"class\":\"active\"}"
fi
