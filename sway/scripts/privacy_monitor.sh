#!/bin/bash

mic_active=false
cam_active=false

# Check if microphone is being used
if lsof /dev/snd/* 2>/dev/null | grep -q "pcm"; then
    mic_active=true
fi

# Check if camera is being used
if lsof /dev/video* 2>/dev/null | grep -q "video"; then
    cam_active=true
fi

# Alternative check using /proc/asound for mic
if [ "$mic_active" = false ] && [ -d "/proc/asound" ]; then
    for card in /proc/asound/card*; do
        if [ -f "$card/pcm0c/sub0/status" ]; then
            status=$(cat "$card/pcm0c/sub0/status" 2>/dev/null)
            if [ "$status" = "RUNNING" ]; then
                mic_active=true
                break
            fi
        fi
    done
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
