#!/bin/zsh

# Definición de colores para que se vea bonito
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- INICIANDO DESPLIEGUE AUTOMATICO (LINUX) ---${NC}"

# 1. Compilar Web
echo -e "${CYAN}1/5 Compilando WEB...${NC}"
flutter build web --release
if [ $? -ne 0 ]; then
    echo -e "${RED}Error en Web${NC}"
    exit 1
fi

# 2. Compilar Android
echo -e "${CYAN}2/5 Compilando ANDROID...${NC}"
flutter build apk --release
if [ $? -ne 0 ]; then
    echo -e "${RED}Error en Android${NC}"
    exit 1
fi

# 3. Limpiar carpeta Public
echo -e "${YELLOW}3/5 Limpiando carpeta public...${NC}"
if [ -d "public" ]; then
    rm -rf public/*
else
    mkdir public
fi

# 4. Copiar Archivos
echo -e "${YELLOW}4/5 Organizando archivos...${NC}"

# Copiar contenido Web
# La bandera -r es recursiva
cp -r build/web/* public/

# Copiar APK y renombrar
APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"
APK_DEST="public/abencerrajes.apk"

if [ -f "$APK_SOURCE" ]; then
    cp "$APK_SOURCE" "$APK_DEST"
    echo -e "${GREEN}APK copiado: abencerrajes.apk${NC}"
else
    echo -e "${RED}NO SE ENCONTRO EL APK.${NC}"
    exit 1
fi

# 5. Desplegar a Firebase
echo -e "${MAGENTA}5/5 Subiendo a Firebase...${NC}"
firebase deploy

echo -e "${GREEN}--- LISTO ---${NC}"