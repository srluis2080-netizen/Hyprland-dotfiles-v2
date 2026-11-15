#!/usr/bin/env bash
# Genera un SVG con hora, minutos y segundos girados a la hora actual
# e imprime su ruta. Un archivo nuevo por segundo (eww recarga la imagen
# cuando cambia la ruta) y borra los anteriores.

HOUR_COLOR="#F2F2F2"     # manecilla de la hora
MIN_COLOR="#D71921"      # manecilla de los minutos
SEC_COLOR="#8C8C8C"      # segundero

DIR="/tmp/eww-clock"
mkdir -p "$DIR"

read -r h m s stamp <<< "$(date '+%I %M %S %H%M%S')"
OUT="$DIR/hands-$stamp.svg"

if [ ! -f "$OUT" ]; then
  read -r ha ma sa <<< "$(awk -v h="$((10#$h))" -v m="$((10#$m))" -v s="$((10#$s))" \
    'BEGIN{printf "%.2f %.2f %.2f", ((h%12)*60+m)*0.5 + s*(0.5/60), m*6 + s*0.1, s*6}')"

  cat > "$OUT" << SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 220" width="220" height="220">
  <rect x="99" y="64" width="22" height="57" rx="11" fill="$HOUR_COLOR" transform="rotate($ha 110 110)"/>
  <rect x="99" y="32" width="22" height="89" rx="11" fill="$MIN_COLOR"  transform="rotate($ma 110 110)"/>
  <rect x="108" y="18" width="4" height="108" rx="2" fill="$SEC_COLOR" transform="rotate($sa 110 110)"/>
  <circle cx="110" cy="110" r="6" fill="$SEC_COLOR"/>
</svg>
SVG

  find "$DIR" -name 'hands-*.svg' ! -name "$(basename "$OUT")" -delete
fi

echo "$OUT"