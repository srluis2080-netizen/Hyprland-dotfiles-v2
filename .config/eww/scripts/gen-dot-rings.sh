#!/usr/bin/env bash
# Genera los SVG de anillos de puntos (estilo Nothing) para eww.
# Uso: gen-dot-rings.sh [carpeta_destino]   (por defecto ~/.config/eww/images/dots)
# Archivos: <nombre>-<puntos_encendidos>.svg
#   s24-<color>-0..24   anillo pequeno de 24 puntos (tiles del panel)  64x64
#   t60-<color>-0..60   anillo grande de 60 puntos (temporizador)      240x240

OUT="${1:-$HOME/.config/eww/images/dots}"
mkdir -p "$OUT"

RED="#D71921"; WHITE="#F2F2F2"; GREY="#8C8C8C"
UNLIT="#4A4A4A"        # color de los puntos apagados

# gen <nombre> <n_puntos> <tamano> <radio_anillo> <radio_punto> <color_encendido>
gen() {
  local name=$1 n=$2 size=$3 R=$4 r=$5 color=$6 lit
  for lit in $(seq 0 "$n"); do
    awk -v n="$n" -v lit="$lit" -v size="$size" -v R="$R" -v r="$r" -v lc="$color" -v uc="$UNLIT" 'BEGIN {
      pi = 3.14159265358979; c = size / 2
      printf "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 %d %d\" width=\"%d\" height=\"%d\">", size, size, size, size
      for (i = 0; i < n; i++) {
        a = 2 * pi * i / n
        x = c + R * sin(a); y = c - R * cos(a)       # empieza arriba, sentido horario
        if (i < lit) { col = lc; rad = r } else { col = uc; rad = r * 0.7 }
        printf "<circle cx=\"%.2f\" cy=\"%.2f\" r=\"%.2f\" fill=\"%s\"/>", x, y, rad, col
      }
      print "</svg>"
    }' > "$OUT/$name-$lit.svg"
  done
}

gen s24-red   24 64  28 2.5 "$RED"
gen s24-white 24 64  28 2.5 "$WHITE"
gen s24-grey  24 64  28 2.5 "$GREY"
gen t60-red   60 240 93 2.6 "$RED"
gen t60-white 60 240 93 2.6 "$WHITE"

echo "Listo: $(ls "$OUT" | wc -l) archivos en $OUT"
