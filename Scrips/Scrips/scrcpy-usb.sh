#!/bin/bash

BITRATE="8M"            
MAX_SIZE="1600"           
FPS="60" 
CODEC="--video-codec=h264"                 

TECLADO="--keyboard=uhid"
MOUSE="--mouse=aoa"

EXTRAS="--turn-screen-off --stay-awake --power-off-on-close" 

AUDIO="--audio-codec=opus"       

scrcpy -b "$BITRATE" -m "$MAX_SIZE" --max-fps "$FPS" $AUDIO $CODEC $EXTRAS $TECLADO $MOUSE "$@"