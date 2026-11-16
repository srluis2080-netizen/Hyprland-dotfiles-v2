#!/usr/bin/env bash
# Emite por stdout un array JSON con 16 alturas (0-48) por cada frame de audio distinto.
# Requiere: cava
BARS=16
ZEROS="[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]"

if ! command -v cava >/dev/null 2>&1; then
  echo "$ZEROS"; exec sleep infinity
fi

CFG="/tmp/eww-cava.conf"
cat > "$CFG" << CONF
[general]
bars = $BARS
framerate = 20

[input]
; si usas PipeWire nativo puedes cambiar a: method = pipewire
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 48
bar_delimiter = 59
frame_delimiter = 10

[smoothing]
noise_reduction = 60
CONF

pkill -f "cava -p $CFG" 2>/dev/null
# El awk final descarta lineas repetidas: en silencio eww no recibe nada
cava -p "$CFG" | sed -u -e 's/;$//' -e 's/;/,/g' -e 's/^/[/' -e 's/$/]/' \
  | awk '$0 != p { print; fflush(); p = $0 }'