#!/usr/bin/env bash

START=$1
DEVICE_NAME=$(hyprctl devices | grep -i touchpad | sed "s/.*\t//g")
TOUCHPAD_FILE="$HOME/.config/hypr/scripts/cache/touchpad_file"
TOUCHPAD_STATE=$(head "$TOUCHPAD_FILE")
#echo "device name = $DEVICE_NAME"
#echo "touchpad file path = $TOUCHPAD_FILE"
#echo "touchpad state = $TOUCHPAD_STATE"

if [ ! -s "$TOUCHPAD_FILE" ]; then
    echo "1" >> $TOUCHPAD_FILE    
    echo "file upload"
fi

if [ "$START" = "-s" ]; then
    hyprctl eval "hl.device({ 
        name = \"$DEVICE_NAME\", 
        enabled = false, 
    })"
    echo "0" > $TOUCHPAD_FILE
    echo $(head $TOUCHPAD_FILE)
fi

if [ "$TOUCHPAD_STATE" = "1" ]; then
    hyprctl eval "hl.device({ 
        name = \"$DEVICE_NAME\", 
        enabled = false, 
    })"
    echo "0" > $TOUCHPAD_FILE
    echo $(head $TOUCHPAD_FILE)
else
    hyprctl eval "hl.device({ 
        name = \"$DEVICE_NAME\", 
        enabled = true, 
    })"
    echo "1" > $TOUCHPAD_FILE
    echo $(head $TOUCHPAD_FILE)
fi
