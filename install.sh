#!/usr/bin/env bash

# Salir si ocurre algún error
set -e

# Colores para mensajes
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m' # Sin color

echo -e "${AZUL}==========================================${NC}"
echo -e "${AZUL}   Instalador de Dotfiles - srluis2080    ${NC}"
echo -e "${AZUL}==========================================${NC}"

# 1. Lista de paquetes necesarios (ajusta según tu gusto)
PAQUETES=(
    hyprland
    waybar
    swaync
    fuzzel
    kitty
    thunar
    btop
    cava
    fastfetch
    fish
    yazi
    ttf-jetbrains-mono-nerd
)

echo -e "\n${AMARILLO}[1/3] Instalando paquetes necesarios...${NC}"
sudo pacman -S --needed --noconfirm "${PAQUETES[@]}"

# 2. Crear respaldo de configuraciones existentes
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
echo -e "\n${AMARILLO}[2/3] Creando respaldo de .config actual en: $BACKUP_DIR${NC}"
mkdir -p "$BACKUP_DIR"

for carpeta in .config/*; do
    nombre=$(basename "$carpeta")
    if [ -d "$HOME/.config/$nombre" ]; then
        cp -r "$HOME/.config/$nombre" "$BACKUP_DIR/"
    fi
done

# 3. Copiar los nuevos dotfiles a ~/.config
echo -e "\n${AMARILLO}[3/3] Copiando nuevas configuraciones a ~/.config...${NC}"
mkdir -p "$HOME/.config"
cp -rf .config/* "$HOME/.config/"

# 4. Copiar scripts personales y darles permisos de ejecución
if [ -d "scripts" ]; then
    echo -e "\n${AMARILLO}[4/4] Instalando scripts personales en ~/.local/bin...${NC}"
    mkdir -p "$HOME/.local/bin"
    cp -rf scripts/* "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/"*
fi


# Actualizar caché de fuentes si copiaste la carpeta fonts
if [ -d "$HOME/.config/fonts" ]; then
    fc-cache -fv > /dev/null 2>&1
fi

echo -e "\n${VERDE}¡Instalación completada con éxito!${NC}"
echo -e "${VERDE}Tu configuración anterior se guardó en: $BACKUP_DIR${NC}"
echo -e "${AZUL}Reinicia tu sesión de Hyprland para aplicar todos los cambios.${NC}"
