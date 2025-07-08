#!/bin/bash

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎨 COLORES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

SEPARADOR="${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📍 RUTA DE INSTALACIÓN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
INSTALL_PATH="$HOME/bin"
SCRIPT_NAME="manager-ssh"
SCRIPT_URL="https://raw.githubusercontent.com/ChristopherAGT/sshws-gcp-config/main/ssh-manager.sh"

echo -e "$SEPARADOR"
echo -e "${YELLOW}📦 Instalador del panel SSH-WS${RESET}"
echo -e "${BLUE}🔗 URL del script:${RESET} $SCRIPT_URL"
echo -e "$SEPARADOR"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📁 Crear carpeta bin si no existe
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${CYAN}📂 Verificando directorio ${INSTALL_PATH}...${RESET}"
mkdir -p "$INSTALL_PATH"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⬇️ Descargar el script
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${CYAN}⬇️ Descargando script...${RESET}"
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH/$SCRIPT_NAME"
if [[ $? -ne 0 || ! -s "$INSTALL_PATH/$SCRIPT_NAME" ]]; then
    echo -e "${RED}❌ Error al descargar el script desde:${RESET} $SCRIPT_URL"
    echo -e "$SEPARADOR"
    exit 1
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ✅ Dar permisos de ejecución
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
chmod +x "$INSTALL_PATH/$SCRIPT_NAME"
echo -e "${GREEN}✅ Permisos de ejecución otorgados.${RESET}"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🔧 Agregar al PATH si es necesario
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if [[ ":$PATH:" != *":$INSTALL_PATH:"* ]]; then
    echo -e "${YELLOW}➕ Agregando $INSTALL_PATH al PATH en .bashrc...${RESET}"
    echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🎉 Mensaje final
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "$SEPARADOR"
echo -e "${GREEN}✅ Instalación completada correctamente.${RESET}"
echo -e "${BLUE}🚀 Puedes iniciar el panel ejecutando:${RESET} ${YELLOW}manager-ssh${RESET}"
echo -e "$SEPARADOR"
