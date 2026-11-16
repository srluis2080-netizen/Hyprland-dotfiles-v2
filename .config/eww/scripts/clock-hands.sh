#!/usr/bin/env bash
# Genera un SVG con hora y minutos, mas un punto que orbita marcando los segundos.
# Imprime la ruta del archivo. Un archivo nuevo por segundo (eww recarga al cambiar la ruta).
# Version ligera: solo aritmetica de bash (unico proceso externo: date).

HOUR_COLOR="#F2F2F2"     # manecilla de la hora
MIN_COLOR="#D71921"      # manecilla de los minutos
DOT_COLOR="#8C8C8C"      # punto de los segundos (gris)

DIR="/tmp/eww-clock"
[ -d "$DIR" ] || mkdir -p "$DIR"

read -r h m s stamp <<< "$(date '+%I %M %S %H%M%S')"
OUT="$DIR/hands-$stamp.svg"

if [ ! -f "$OUT" ]; then
  h=$((10#$h)); m=$((10#$m)); s=$((10#$s))
  ha=$(( ((h % 12) * 3600 + m * 60 + s) * 5 / 6 ))   # grados x 100
  ma=$(( (m * 60 + s) * 10 ))                         # grados x 100
  sa=$(( s * 600 ))                                   # grados x 100
  printf -v ha '%d.%02d' $((ha / 100)) $((ha % 100))
  printf -v ma '%d.%02d' $((ma / 100)) $((ma % 100))
  printf -v sa '%d.%02d' $((sa / 100)) $((sa % 100))

  printf '%s\n' \
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 220" width="220" height="220">' \
    "  <rect x=\"99\" y=\"64\" width=\"22\" height=\"57\" rx=\"11\" fill=\"$HOUR_COLOR\" transform=\"rotate($ha 110 110)\"/>" \
    "  <rect x=\"99\" y=\"40\" width=\"22\" height=\"81\" rx=\"11\" fill=\"$MIN_COLOR\" transform=\"rotate($ma 110 110)\"/>" \
    "  <circle cx=\"110\" cy=\"28\" r=\"7\" fill=\"$DOT_COLOR\" transform=\"rotate($sa 110 110)\"/>" \
    '</svg>' > "$OUT"

  # limpieza ocasional (cada 20 s) de archivos viejos
  [ $((s % 20)) -eq 0 ] && find "$DIR" -name 'hands-*.svg' -mmin +1 -delete
fi

echo "$OUT"