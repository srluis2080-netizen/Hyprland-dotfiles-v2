#!/usr/bin/env bash
# Devuelve JSON: {"temp":"11","icon":"moon-cloud"}
CITY="${CITY:-Milagro,Guayas,Ecuador}"

raw=$(curl -s --max-time 10 "https://wttr.in/${CITY}?m&format=%t|%C" 2>/dev/null)
temp=$(echo "$raw" | cut -d'|' -f1 | grep -oE '[-+]?[0-9]+' | head -1 | tr -d '+')
cond=$(echo "$raw" | cut -d'|' -f2 | tr 'A-Z' 'a-z')

[ -z "$temp" ] && { echo '{"temp":"--","icon":"cloud"}'; exit 0; }

h=$((10#$(date +%H)))
if [ "$h" -ge 18 ] || [ "$h" -lt 6 ]; then night=1; else night=0; fi

case "$cond" in
  *thunder*)                          icon="storm" ;;
  *snow*|*sleet*|*blizzard*|*ice*)    icon="snow" ;;
  *rain*|*drizzle*|*shower*)          icon="rain" ;;
  *fog*|*mist*|*haze*)                icon="fog" ;;
  *partly*)  [ $night = 1 ] && icon="moon-cloud" || icon="sun-cloud" ;;
  *cloud*|*overcast*)                 icon="cloud" ;;
  *clear*|*sunny*) [ $night = 1 ] && icon="moon" || icon="sun" ;;
  *)                                  icon="cloud" ;;
esac

printf '{"temp":"%s","icon":"%s"}\n' "$temp" "$icon"
