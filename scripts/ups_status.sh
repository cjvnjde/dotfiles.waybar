#!/bin/bash

UPS_STATUS=$(apcaccess status)

UPS_CHARGE=$(echo "$UPS_STATUS" | awk '/BCHARGE/{print $3}')
CHARGING_STATUS=$(echo "$UPS_STATUS" | awk '/STATUS/{print $3}')

if [[ "$CHARGING_STATUS" == "ONLINE" ]]; then
    CHARGING=true
else
    CHARGING=false
fi

percentage="${UPS_CHARGE%.*}"
icons=("" "" "" "" "")
index=$((percentage / 20))
if [[ $percentage -eq 100 ]]; then
    index=4
fi

if [[ $CHARGING == true ]]; then
    ICON=""
else
    ICON="${icons[index]} "
fi

selected_icon=$(select_icon "$UPS_CHARGE")

echo "$ICON $UPS_CHARGE%"

