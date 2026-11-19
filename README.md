# Hyprland Dotfiles v2

|-Inspirado en Nothing os/glyph-|

Una configuración de **Hyprland** ligera, limpia y transparente para **Arch Linux / CachyOS**, optimizada para bajo consumo de recursos (~1.2 GB de RAM en reposo).

Este repositorio ya viene organizado siguiendo la estructura real de `~/.config/` para que puedas instalarlo de forma automática con `install.sh` o simplemente explorar y copiar las carpetas que más te gusten.

---

## Capturas de pantalla

### Widgets de eww - Panel - Reloj - Clima
<img width="928" height="1152" alt="collaje-widgets" src="https://github.com/user-attachments/assets/090c5b4b-e069-45a5-991c-2df39119d9aa" />


### Fastfetch, Kitty y Waybar
<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/ca1aed3e-2920-4a5a-b4b9-43376b1748bb" />



### Barra de estado
<img width="1600" height="39" alt="image" src="https://github.com/user-attachments/assets/3969c8ee-8c85-4930-b2d6-89219197d720" />



### Centro de notificaciones (SwayNC)
<img width="518" height="717" alt="image" src="https://github.com/user-attachments/assets/a119dda4-9752-4333-89ea-8bfd376c69fd" />

### Launcher de apps (Fuzzel)
<img width="1600" height="900" alt="fuzzel_captura" src="https://github.com/user-attachments/assets/5c93a5c9-a2c9-4f9f-933f-1b5452e7251d" />

### Pantalla de bloqueo (Hyprlock)
<img width="1600" height="900" alt="hyprlock_captura" src="https://github.com/user-attachments/assets/e94ca379-8476-46c3-bbbc-a650bd87089c" />

---

## Componentes y Aplicaciones

| Aplicación | Función | Ruta en el repositorio |
| :--- | :--- | :--- |
| **Hyprland** | Compositor / Gestor de ventanas Wayland | `.config/hypr/` |
| **Waybar** | Barra de estado principal | `.config/waybar/` |
| **Fuzzel** | Lanzador de aplicaciones y temas | `.config/fuzzel/` |
| **SwayNC** | Centro de notificaciones | `.config/swaync/` |
| **Kitty** | Emulador de terminal | `.config/kitty/` |
| **Fish** | Shell interactiva | `.config/fish/` |
| **Fastfetch** | Información del sistema en terminal | `.config/fastfetch/` |
| **Btop** | Monitor de recursos del sistema | `.config/btop/` |
| **Cava** | Visualizador de audio en terminal | `.config/cava/` |
| **Thunar & Yazi** | Gestores de archivos (gráfico y terminal) | `.config/Thunar/`, `.config/yazi/` |
| **GTK & Fuentes** | Temas GTK 3/4 y tipografías | `.config/gtk-3.0/`, `.config/gtk-4.0/`, `.config/fonts/` |
| **EWW** | Widgets personalizados | `.config/eww/` |

---

## Estructura del Repositorio

```text
Hyprland-dotfiles-v2/
├── .config/
│   ├── Thunar/
│   ├── btop/
│   ├── cava/
│   ├── fastfetch/
│   ├── fish/
│   ├── fonts/
│   ├── fuzzel/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   ├── hypr/
│   ├── kitty/
│   ├── swaync/
│   ├── uwsm/
│   ├── waybar/
│   └── yazi/
├── scripts/          # Scripts personales (se instalan en ~/.local/bin)
└── install.sh        # Script de instalación automática y respaldo
```

---

## Instalación

### Opción 1: Instalación automática (Recomendada)
El script `install.sh` instala los paquetes necesarios mediante `pacman`, crea una copia de seguridad automática de tu `~/.config` actual y copia los dotfiles y scripts en su lugar:

```bash
git clone https://github.com
cd Hyprland-dotfiles-v2
chmod +x install.sh
./install.sh
```

### Opción 2: Instalación manual
Si solo quieres copiar alguna configuración en específico:

```bash
git clone https://github.com
cp -r Hyprland-dotfiles-v2/.config/* ~/.config/
```
