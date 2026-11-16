#!/usr/bin/env bash
# Genera los SVG del movil dibujado (vista trasera estilo Nothing Phone) para eww.
# Uso: gen-phone.sh [carpeta_destino]   (por defecto ~/.config/eww/images/phone)
# Archivos:
#   phone-white-0..10  tira de LED (10 segmentos) encendida en blanco (bateria normal)
#   phone-red-0..10    igual, en rojo (cargando o bateria baja)
#   phone-off          movil apagado / desconectado (todo en gris oscuro)

OUT="${1:-$HOME/.config/eww/images/phone}"
mkdir -p "$OUT"

WHITE="#F2F2F2"; RED="#D71921"
SURFACE="#0E0E0E"; LINE="#2A2A2A"; MUTE="#4A4A4A"; GREY="#8C8C8C"; BLACK="#000000"; TILE="#1A1A1A"

# build <segmentos_encendidos> <color_led> <borde_cuerpo> <borde_camaras> <flash> <bobina>
build() {
  local lit=$1 led=$2 body=$3 cam=$4 flash=$5 coil=$6 i y col
  printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 240" width="120" height="240">'
  printf '<rect x="3" y="3" width="114" height="234" rx="26" fill="%s" stroke="%s" stroke-width="2"/>' "$SURFACE" "$body"
  printf '<circle cx="36" cy="38" r="12" fill="%s" stroke="%s" stroke-width="2"/>' "$BLACK" "$cam"
  printf '<circle cx="36" cy="68" r="12" fill="%s" stroke="%s" stroke-width="2"/>' "$BLACK" "$cam"
  printf '<circle cx="62" cy="34" r="3" fill="%s"/>' "$flash"
  printf '<circle cx="54" cy="150" r="30" fill="none" stroke="%s" stroke-width="2"/>' "$coil"
  printf '<circle cx="54" cy="150" r="18" fill="none" stroke="%s" stroke-width="2"/>' "$coil"
  for i in 0 1 2 3 4 5 6 7 8 9; do          # i = 0 es el segmento de abajo
    y=$((200 - i * 18))
    if [ "$i" -lt "$lit" ]; then col=$led; else col=$LINE; fi
    printf '<rect x="95" y="%d" width="7" height="14" rx="3.5" fill="%s"/>' "$y" "$col"
  done
  printf '</svg>\n'
}

for n in $(seq 0 10); do
  build "$n" "$WHITE" "$LINE" "$MUTE" "$GREY" "$LINE" > "$OUT/phone-white-$n.svg"
  build "$n" "$RED"   "$LINE" "$MUTE" "$GREY" "$LINE" > "$OUT/phone-red-$n.svg"
done
build 0 "$LINE" "$LINE" "$LINE" "$LINE" "$TILE" > "$OUT/phone-off.svg"

echo "Listo: $(ls "$OUT" | wc -l) archivos en $OUT"
