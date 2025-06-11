#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Obtener directorio actual donde se ejecuta el script
RUTA="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGINS_DIR="$ZSH_CUSTOM/plugins"
THEMES_DIR="$ZSH_CUSTOM/themes"
FONT_DIR="$HOME/.local/share/fonts"
ZSHRC_FILE="$HOME/.zshrc"

# Función para instalar Micro y plugins
install_micro() {
    echo -e "${YELLOW}\nInstalando Micro +++plugins...${NC}"
    if ! command -v micro &>/dev/null; then
        echo -e "${GREEN}Descargando Micro...${NC}"
        curl https://getmic.ro | bash
        sudo mv micro /usr/local/bin/
    else
        echo -e "${GREEN}Micro ya está instalado.${NC}"
    fi

    plugins=("yapf" "jump" "lsp" "misspell" "snippets" "autoclose" "comment" "diff" "ftoptions" "linter" "literate" "status")
    for plugin in "${plugins[@]}"; do
        if ! micro -plugin list | grep -q "$plugin"; then
            echo -e "${YELLOW}Instalando plugin: $plugin${NC}"
            micro -plugin install "$plugin"
        else
            echo -e "${GREEN}$plugin ya está instalado.${NC}"
        fi
    done
}

# Función para exportar atajos de GNOME
export_keybindings() {
    echo -e "${YELLOW}\nExportando atajos de teclado...${NC}"
    gsettings list-recursively | grep -E "org.gnome.settings-daemon.plugins.media-keys|org.gnome.desktop.wm.keybindings|org.gnome.shell.keybindings" > "${RUTA}/gnome-key-backup.txt"
    dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ > "${RUTA}/custom-key-backup.dconf"
    echo -e "${GREEN}¡Backup guardado en:${NC}"
    echo -e "  - ${BLUE}${RUTA}/gnome-key-backup.txt${NC}"
    echo -e "  - ${BLUE}${RUTA}/custom-key-backup.dconf${NC}"
}

# Función para restaurar atajos de GNOME
restore_keybindings() {
    echo -e "${YELLOW}\nRestaurando atajos de teclado...${NC}"
    if [[ -f "${RUTA}/gnome-key-backup.txt" ]]; then
        while read -r line; do
            gsettings set ${line}
        done < "${RUTA}/gnome-key-backup.txt"
    else
        echo -e "${RED}¡Archivo gnome-key-backup.txt no encontrado en ${RUTA}!${NC}"
    fi
    
    if [[ -f "${RUTA}/custom-key-backup.dconf" ]]; then
        dconf load /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ < "${RUTA}/custom-key-backup.dconf"
    else
        echo -e "${RED}¡Archivo custom-key-backup.dconf no encontrado en ${RUTA}!${NC}"
    fi
    
    echo -e "${GREEN}¡Atajos restaurados!${NC}"
    echo -e "${YELLOW}Reinicia GNOME (Alt + F2 → 'r') para aplicar cambios.${NC}"
}

# Función para exportar la configuración de la terminal
export_terminal() {
    echo -e "${YELLOW}\nExportando la configuración de la terminal...${NC}"
    dconf dump /org/gnome/terminal/ > "${RUTA}/gnome-terminal-backup.txt"
    echo -e "${GREEN}¡Backup guardado en:${NC}"
    echo -e "  - ${BLUE}${RUTA}/gnome-terminal-backup.txt${NC}"
}

# Función para restaurar la configuración de la terminal
restore_terminal() {
    echo -e "${YELLOW}\nRestaurando configuración de la terminal...${NC}"
    if [[ -f "${RUTA}/gnome-terminal-backup.txt" ]]; then
        dconf load /org/gnome/terminal/ < "${RUTA}/gnome-terminal-backup.txt"
        echo -e "${GREEN}¡Configuración restaurada!${NC}"
    else
        echo -e "${RED}¡Archivo gnome-terminal-backup.txt no encontrado en ${RUTA}!${NC}"
    fi
}

############ ZSH + oh-my-zsh + power_level_10k

# ---- Funciones principales ----

install_zsh() {
    echo -e "${YELLOW}\n[1/7] Instalando Zsh...${NC}"
    if ! command -v zsh &>/dev/null; then
        sudo apt update && sudo apt install -y zsh || {
            echo -e "${RED}Error: Falló la instalación de Zsh.${NC}"
            exit 1
        }
        echo -e "${GREEN}Zsh instalado.${NC}"
    else
        echo -e "${BLUE}Zsh ya está instalado.${NC}"
    fi
}

install_ohmyzsh() {
    echo -e "${YELLOW}\n[2/7] Instalando Oh My Zsh...${NC}"
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
            echo -e "${RED}Error: Falló la instalación de Oh My Zsh.${NC}"
            exit 1
        }
        echo -e "${GREEN}Oh My Zsh instalado.${NC}"
    else
        echo -e "${BLUE}Oh My Zsh ya está instalado.${NC}"
    fi
}

install_powerlevel10k() {
    echo -e "${YELLOW}\n[3/7] Instalando Powerlevel10k...${NC}"
    if [ ! -d "$THEMES_DIR/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEMES_DIR/powerlevel10k" || {
            echo -e "${RED}Error: Falló la clonación de Powerlevel10k.${NC}"
            exit 1
        }
        echo -e "${GREEN}Powerlevel10k instalado.${NC}"
    else
        echo -e "${BLUE}Powerlevel10k ya está instalado.${NC}"
    fi
}

install_plugins() {
    echo -e "${YELLOW}\n[4/7] Instalando plugins esenciales...${NC}"

    declare -A plugins=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
        ["you-should-use"]="https://github.com/MichaelAquilina/zsh-you-should-use"
    )

    for plugin in "${!plugins[@]}"; do
        if [ ! -d "$PLUGINS_DIR/$plugin" ]; then
            echo -e "${BLUE}Instalando $plugin...${NC}"
            git clone --depth=1 "${plugins[$plugin]}" "$PLUGINS_DIR/$plugin" || {
                echo -e "${RED}Error: Falló la instalación de $plugin.${NC}"
                continue
            }
        else
            echo -e "${BLUE}$plugin ya está instalado.${NC}"
        fi
    done
}

install_fonts() {
    echo -e "${YELLOW}\n[5/7] Instalando fuentes necesarias...${NC}"
    
    mkdir -p "$FONT_DIR"
    
    echo -e "${BLUE}Instalando MesloLGS Nerd Font...${NC}"
    for font in Regular Bold Italic BoldItalic; do
        font_file="MesloLGS NF ${font}.ttf"
        if [ ! -f "$FONT_DIR/$font_file" ]; then
            wget -q -P "$FONT_DIR" "https://github.com/romkatv/powerlevel10k-media/raw/master/${font_file}" || {
                echo -e "${RED}Error al descargar $font_file${NC}"
                continue
            }
            echo -e "${GREEN}$font_file instalada.${NC}"
        else
            echo -e "${BLUE}$font_file ya existe.${NC}"
        fi
    done
    
    fc-cache -fv >/dev/null
}

configure_zshrc() {
    echo -e "${YELLOW}\n[6/7] Configurando ~/.zshrc...${NC}"

    # Crear backup
    cp "$ZSHRC_FILE" "$ZSHRC_FILE.backup" 2>/dev/null

    # Crear nuevo .zshrc con la configuración esencial
    cat > "$ZSHRC_FILE" << 'EOL'
# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Configuración de plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    you-should-use
)

# Cargar Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Configuración de plugins
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'

# Optimizaciones
DISABLE_UPDATE_PROMPT=true
DISABLE_UNTRACKED_FILES_DIRTY=true

# Cargar configuración de Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Cargar completions adicionales
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

#Alias
alias ll="ls -al"

# Inicializar completions
autoload -Uz compinit
compinit
EOL

    echo -e "${GREEN}Configuración aplicada. Backup en ~/.zshrc.backup${NC}"
}

mensaje_final() {
    echo -e "${YELLOW}\n[7/7] Pasos finales${NC}"
    echo -e "${GREEN}\n¡Instalación completada!${NC}"
    echo -e "\n${YELLOW}Configura manualmente tu terminal para usar 'MesloLGS NF':${NC}"
    echo -e "1. Abre preferencias de tu terminal"
    echo -e "2. Busca la opción de fuentes"
    echo -e "3. Selecciona 'MesloLGS NF'"
    echo -e "\nEjecuta manualmente en una terminal secundaria:"
    echo -e "1. Cambiar shell a Zsh: ${BLUE}chsh -s \$(which zsh)${NC}"
    echo -e "2. Cerrar y abrir una nueva terminal"
    echo -e "3. Seguir el asistente de Powerlevel10k"
    echo -e "4. Para personalizar: ${BLUE}p10k configure${NC}"
}

mejorarZSH(){
	# ---- Ejecución ----
	echo -e "${BLUE}========================================${NC}"
	echo -e "${BLUE}  INSTALACIÓN COMPLETA DE POWERLEVEL10K  ${NC}"
	echo -e "${BLUE}  con Plugins Esenciales y Fuentes       ${NC}"
	echo -e "${BLUE}========================================${NC}"
	
	install_zsh
	install_ohmyzsh
	install_powerlevel10k
	install_plugins
	install_fonts
	configure_zshrc
	mensaje_final
}

focus_mouse(){
	if gsettings set org.gnome.desktop.wm.preferences focus-mode 'sloppy'; then
	    echo -e  "${GREEN}Configuración aplicada correctamente.${NC}"
	else
	    echo -e  "${RED}Error al aplicar la configuración.${NC}" >&2
	    exit 1
	fi
}
###############################
#################################
######################################
###############################################
##################################################

# Función para mostrar el menú
show_menu() {
    clear
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}         HERRAMIENTAS    DE     CONFIGURACIÓN      ${NC}"
    echo -e "${BLUE}            Entorno recomendado kali-gnome         ${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo -e "1) ${YELLOW}Instalar Micro y plugins${NC}"
    echo -e "2) ${YELLOW}Exportar atajos de GNOME${NC}"
    echo -e "3) ${YELLOW}Restaurar atajos de GNOME${NC}"
    echo -e "4) ${YELLOW}Exportar configuración terminal${NC}"
    echo -e "5) ${YELLOW}Restaurar configuración terminal${NC}"
    echo -e "6) ${YELLOW}Mejorar zsh + oh_my_zsh + power_level_10k${NC}"
    echo -e "7) ${YELLOW}focus follows mouse(seguimiento de mouse)${NC}"
    echo -e "0) ${RED}Salir${NC}"
    echo -e "${BLUE}___________________________________________________${NC}"
}

# Bucle principal del menú
while true; do
    show_menu
    read -p "Selecciona un número #[0-*]: " choice
    case $choice in
        1) install_micro ;;
        2) export_keybindings ;;
        3) restore_keybindings ;;
        4) export_terminal ;;
        5) restore_terminal ;;
        6) mejorarZSH ;;
        7) focus_mouse ;;
        0) 
            echo -e "${RED}Saliendo...${NC}"
            echo -e "${GREEN}Reinicia el sistema si restauro(recomendado).${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Opción inválida. Intenta de nuevo.${NC}" ;;
    esac
    read -p "Presiona Enter para continuar..."
done
