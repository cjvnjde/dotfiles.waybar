#!/bin/bash

mic_active=false
cam_active=false

# Check if microphone is being used by looking for capture devices only
# Check PulseAudio/PipeWire for active recording sources
if command -v pactl >/dev/null 2>&1; then
    # Check for active source outputs (recording streams)
    if pactl list source-outputs 2>/dev/null | grep -q "Source Output"; then
        mic_active=true
    fi
elif command -v pw-cli >/dev/null 2>&1; then
    # Check PipeWire for recording streams
    if pw-cli list-objects 2>/dev/null | grep -A 20 "type:PipeWire:Interface:Node" | grep -B 5 -A 15 "media.class.*Source" | grep -q "state.*running"; then
        mic_active=true
    fi
else
    # Fallback: check only capture devices in /proc/asound
    if [ -d "/proc/asound" ]; then
        for card in /proc/asound/card*; do
            # Only check capture devices (pcmXc - 'c' for capture)
            for capture_device in "$card"/pcm*c/sub*/status; do
                if [ -f "$capture_device" ]; then
                    status=$(cat "$capture_device" 2>/dev/null)
                    if [ "$status" = "RUNNING" ]; then
                        mic_active=true
                        break 2
                    fi
                fi
            done
        done
    fi
fi

# Check if camera is being used
if lsof /dev/video* 2>/dev/null | grep -q "video"; then
    cam_active=true
fi

# Generate colored dots and tooltip
cam_color="gray"
mic_color="gray"
tooltip_parts=()

if [ "$cam_active" = true ]; then
    cam_color="red"
    tooltip_parts+=("Camera: ACTIVE")
else
    tooltip_parts+=("Camera: inactive")
fi

if [ "$mic_active" = true ]; then
    mic_color="orange"
    tooltip_parts+=("Microphone: ACTIVE")
else
    tooltip_parts+=("Microphone: inactive")
fi

# Join tooltip parts
tooltip="${tooltip_parts[0]} | ${tooltip_parts[1]}"

# Create output with individually colored dots
output="<span color='$cam_color'>●</span> <span color='$mic_color'>●</span>"

echo "{\"text\":\"$output\", \"tooltip\":\"$tooltip\"}"
