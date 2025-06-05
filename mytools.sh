#!/bin/bash

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Obtener directorio actual donde se ejecuta el script
RUTA="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
        0) 
            echo -e "${RED}Saliendo...${NC}"
            echo -e "${GREEN}Reinicia el sistema (recomendado).${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Opción inválida. Intenta de nuevo.${NC}" ;;
    esac
    read -p "Presiona Enter para continuar..."
done
