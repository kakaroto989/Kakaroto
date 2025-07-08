#!/bin/bash

# ╔════════════════════════════════════════════════════════╗
# ║        📦 GESTIÓN DE REPOSITORIOS EN ARTIFACT REGISTRY       ║
# ╚════════════════════════════════════════════════════════╝

# 🎨 Colores
neutro='\033[0m'
rojo='\033[0;31m'
verde='\033[0;32m'
cyan='\033[0;36m'
amarillo='\033[1;33m'

# 📁 Directorio temporal para almacenamiento intermedio
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT  # 🔐 Limpieza automática al salir

# 🎡 Spinner de carga con mensaje personalizado
spinner() {
  local pid=$1
  local mensaje="$2"
  local delay=0.1
  local spinstr='|/-\\'

  echo -ne "${cyan}${mensaje} "
  while kill -0 "$pid" 2>/dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  echo -e " ${verde}✔ Completado${neutro}"
}

# 🌍 Definición de regiones y códigos
REGIONS=(
  "🇺🇸 us-central1 (Iowa)" "🇺🇸 us-west1 (Oregón)" "🇺🇸 us-west2 (Los Ángeles)"
  "🇺🇸 us-west3 (Salt Lake City)" "🇺🇸 us-west4 (Las Vegas)" "🇺🇸 us-east1 (Carolina del Sur)"
  "🇺🇸 us-east4 (Virginia del Norte)" "🇨🇦 northamerica-northeast1 (Montreal)" "🇨🇦 northamerica-northeast2 (Toronto)"
  "🇧🇷 southamerica-east1 (São Paulo)" "🇨🇱 southamerica-west1 (Santiago)"
  "🇪🇺 europe-north1 (Finlandia)" "🇪🇺 europe-west1 (Bélgica)" "🇪🇺 europe-west2 (Londres)"
  "🇪🇺 europe-west3 (Fráncfort)" "🇪🇺 europe-west4 (Países Bajos)" "🇪🇺 europe-west6 (Zúrich)"
  "🇪🇸 europe-southwest1 (Madrid)" "🇮🇹 europe-southwest2 (Milán)" "🇫🇷 europe-west9 (París)"
  "🇸🇪 europe-central2 (Varsovia)" "🇦🇺 australia-southeast1 (Sídney)" "🇦🇺 australia-southeast2 (Melbourne)"
  "🇮🇳 asia-south1 (Mumbai)" "🇮🇳 asia-south2 (Delhi)" "🇯🇵 asia-northeast1 (Tokio)"
  "🇯🇵 asia-northeast2 (Osaka)" "🇯🇵 asia-northeast3 (Sendai)" "🇸🇬 asia-southeast1 (Singapur)"
  "🇮🇩 asia-southeast2 (Yakarta)" "🇹🇭 asia-southeast3 (Bangkok)" "🇰🇷 asia-east1 (Taiwán)"
  "🇰🇷 asia-east2 (Hong Kong)" "🇸🇦 me-central1 (Dammam)" "🇶🇦 me-west1 (Doha)"
  "🇿🇦 africa-south1 (Johannesburgo)" "🇦🇪 me-central2 (E.A.U.)" "🇰🇪 africa-east1 (Nairobi)"
  "🇩🇪 europe-central2 (Berlín)" "🇫🇷 europe-west10 (Marsella)" "🇺🇸 us-east5 (Columbus)"
)

REGION_CODES=(
  "us-central1" "us-west1" "us-west2" "us-west3" "us-west4" "us-east1" "us-east4"
  "northamerica-northeast1" "northamerica-northeast2" "southamerica-east1" "southamerica-west1"
  "europe-north1" "europe-west1" "europe-west2" "europe-west3" "europe-west4" "europe-west6"
  "europe-southwest1" "europe-southwest2" "europe-west9" "europe-central2"
  "australia-southeast1" "australia-southeast2"
  "asia-south1" "asia-south2" "asia-northeast1" "asia-northeast2" "asia-northeast3"
  "asia-southeast1" "asia-southeast2" "asia-southeast3"
  "asia-east1" "asia-east2"
  "me-central1" "me-west1" "africa-south1" "me-central2" "africa-east1"
  "europe-central2" "europe-west10" "us-east5"
)

# 🔍 Función para buscar repositorios en paralelo
buscar_repositorios_en_paralelo() {
  MAX_JOBS=8
  JOBS=0

  for region in "${REGION_CODES[@]}"; do
    {
      repos=$(gcloud artifacts repositories list --location="$region" --format="value(name)" 2>/dev/null)
      while read -r repo; do
        [[ -n "$repo" ]] && echo "$region|$repo"
      done <<< "$repos"
    } > "$TEMP_DIR/$region.txt" &

    ((JOBS++))
    if (( JOBS >= MAX_JOBS )); then
      wait -n
      ((JOBS--))
    fi
  done
  wait
}

# ╔════════════════════════════════════════════════════════╗
# ║            MENÚ PRINCIPAL: CREAR O USAR REPOSITORIO    ║
# ╚════════════════════════════════════════════════════════╝

echo -e "${cyan}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦  GESTIÓN DE REPOSITORIO EN ARTIFACT REGISTRY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

PS3="🎯 Seleccione una opción: "
select opcion in "Crear nuevo repositorio" "Usar uno existente" "Cancelar"; do
  case $REPLY in
    1)
      echo -e "${cyan}"
      echo "📍 SELECCIÓN DE REGIÓN PARA EL NUEVO REPOSITORIO"
      echo -e "${neutro}"

      PS3="Elige la región para el nuevo repositorio: "
      select region in "${REGIONS[@]}"; do
        REGION="${REGION_CODES[$REPLY-1]}"
        echo -e "${verde}✔ Región seleccionada: $REGION${neutro}"
        break
      done

      echo
      read -p "📝 Ingresa el nombre del nuevo repositorio: " REPO_NAME
      if [[ -z "$REPO_NAME" ]]; then
        echo -e "${rojo}❌ El nombre del repositorio no puede estar vacío.${neutro}"
        exit 1
      fi

      echo -e "${cyan}🚧 Creando repositorio \"$REPO_NAME\" en la región \"$REGION\"...${neutro}"
      gcloud artifacts repositories create "$REPO_NAME" \
        --repository-format=docker \
        --location="$REGION" \
        --description="Repositorio Docker creado por script"

      echo -e "${verde}✅ Repositorio creado exitosamente.${neutro}"
      break
      ;;
    2)
      #echo -e "${cyan}🔍 Buscando repositorios existentes en todas las regiones...${neutro}"
      echo
      REPO_LIST=()
      REPO_REGIONS=()

      buscar_repositorios_en_paralelo &
      pid=$!
      spinner "$pid" "🔍 Buscando repositorios existentes en todas las regiones..."
      wait "$pid"

      for file in "$TEMP_DIR"/*.txt; do
        while IFS='|' read -r region repo; do
          REPO_LIST+=("$repo")
          REPO_REGIONS+=("$region")
        done < "$file"
      done

      if [[ ${#REPO_LIST[@]} -eq 0 ]]; then
        echo -e "${rojo}❌ No se encontraron repositorios disponibles.${neutro}"
        exit 1
      fi

      echo -e "${amarillo}\n📂 Repositorios encontrados:${neutro}"
      PS3="🎯 Seleccione el repositorio que desea usar: "
      select repo in "${REPO_LIST[@]}" "Cancelar"; do
        if [[ "$REPLY" -gt 0 && "$REPLY" -le ${#REPO_LIST[@]} ]]; then
          REPO_NAME=$(basename "$repo")
          REGION="${REPO_REGIONS[$REPLY-1]}"
          echo -e "${verde}✔ Repositorio seleccionado: $REPO_NAME (Región: $REGION)${neutro}"
          break
        elif [[ "$REPLY" -eq $((${#REPO_LIST[@]}+1)) ]]; then
          echo -e "${amarillo}⚠️  Cancelado por el usuario.${neutro}"
          exit 0
        else
          echo -e "${rojo}❌ Selección inválida.${neutro}"
        fi
      done
      break
      ;;
    3)
      echo -e "${amarillo}⚠️  Cancelado por el usuario.${neutro}"
      exit 0
      ;;
    *)
      echo -e "${rojo}❌ Opción inválida. Intenta nuevamente.${neutro}"
      ;;
  esac
done

echo -e "${cyan}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 OBTENIENDO ID DEL PROYECTO ACTIVO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${rojo}❌ No se pudo obtener el ID del proyecto. Ejecuta 'gcloud init' primero.${neutro}"
    exit 1
fi
echo -e "${verde}✔ Proyecto activo: $PROJECT_ID${neutro}"

echo -e "${cyan}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 VERIFICANDO EXISTENCIA DEL REPOSITORIO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EXISTS=$(gcloud artifacts repositories list \
    --location="$REGION" \
    --filter="name~$REPO_NAME" \
    --format="value(name)")

if [[ -n "$EXISTS" ]]; then
    echo -e "${amarillo}⚠️ El repositorio '$REPO_NAME' ya existe. Omitiendo creación.${neutro}"
else
    echo -e "${azul}📦 Creando repositorio...${neutro}"
    gcloud artifacts repositories create "$REPO_NAME" \
      --repository-format=docker \
      --location="$REGION" \
      --description="Repositorio Docker para SSH-WS en GCP" \
      --quiet
    [[ $? -ne 0 ]] && echo -e "${rojo}❌ Error al crear el repositorio.${neutro}" && exit 1
    echo -e "${verde}✅ Repositorio creado correctamente.${neutro}"
fi

echo -e "${cyan}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 COMPROBANDO AUTENTICACIÓN DOCKER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ! grep -q "$REGION-docker.pkg.dev" ~/.docker/config.json 2>/dev/null; then
    echo -e "${azul}🔐 Configurando Docker para autenticación...${neutro}"
    gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet
    echo -e "${verde}✅ Docker autenticado correctamente.${neutro}"
else
    echo -e "${verde}🔐 Docker ya autenticado. Omitiendo configuración.${neutro}"
fi
          
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🖼️ OPCIÓN DE IMAGEN EXISTENTE O NUEVA
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "${cyan}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🖼️ OPCIÓN DE IMAGEN DOCKER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

PS3=$'\e[33mSeleccione una opción:\e[0m '
select imagen_opcion in "Crear nueva imagen" "Usar imagen existente" "Cancelar"; do
    case $REPLY in
        1)
            imagen_opcion="Crear nueva imagen"
            break
            ;;
        2)
            echo -e "${azul}🔍 Buscando imágenes en el repositorio '${REPO_NAME}' en la región '${REGION}'...${neutro}"
            FULL_REPO_PATH="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME"

            mapfile -t PAQUETES < <(gcloud artifacts docker images list "$FULL_REPO_PATH" --format="value(package)" 2>/dev/null)
            OPCIONES=()
            OPCIONES_INFO=()

            for paquete in "${PAQUETES[@]}"; do
                TAGS=$(gcloud artifacts docker tags list "$paquete" --format="value(tag,digest)" 2>/dev/null)
                while IFS=$'\t' read -r tag digest; do
                    imagen_name=$(basename "$paquete")
                    tag_clean=$(basename "$tag")
                    OPCIONES+=("$FULL_REPO_PATH/$imagen_name:$tag_clean")
                    OPCIONES_INFO+=("$imagen_name:$tag_clean (Digest: ${digest:0:12})")
                done <<< "$TAGS"
            done

            if [[ ${#OPCIONES[@]} -eq 0 ]]; then
                echo -e "${rojo}❌ No se encontraron imágenes etiquetadas en el repositorio.${neutro}"
                echo -e "${amarillo}🔁 Se procederá a crear una nueva imagen.${neutro}"
                imagen_opcion="Crear nueva imagen"
                break
            fi

            echo -e "${cyan}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📂 Seleccione una imagen existente:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "${neutro}"

            PS3=$'\e[33mSeleccione una imagen:\e[0m '
            select opcion in "${OPCIONES_INFO[@]}" "Cancelar"; do
                if [[ "$REPLY" -gt 0 && "$REPLY" -le ${#OPCIONES[@]} ]]; then
                    IMAGE_FULL="${OPCIONES[$REPLY-1]}"
                    IMAGE_NAME=$(basename "${IMAGE_FULL%%:*}")
                    IMAGE_TAG=$(basename "${IMAGE_FULL##*:}")
                    IMAGE_PATH="${IMAGE_FULL%:*}"
                    imagen_opcion="Usar imagen existente"
                    echo -e "${verde}✔ Imagen seleccionada: $IMAGE_NAME:$IMAGE_TAG${neutro}"
                    break 2
                elif [[ "$REPLY" -eq $((${#OPCIONES[@]} + 1)) ]]; then
                    echo -e "${amarillo}⚠️ Cancelado por el usuario.${neutro}"
                    exit 0
                else
                    echo -e "${rojo}❌ Selección inválida. Intenta de nuevo.${neutro}"
                fi
            done
            ;;
        3)
            echo -e "${amarillo}⚠️ Cancelado por el usuario.${neutro}"
            exit 0
            ;;
        *)
            echo -e "${rojo}❌ Opción inválida. Intenta nuevamente.${neutro}"
            ;;
    esac
done

# 🔁 Solo se ejecuta si se eligió crear una nueva imagen
if [[ "$imagen_opcion" == "Crear nueva imagen" ]]; then
    echo -e "${cyan}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🏗️ CONSTRUCCIÓN DE IMAGEN DOCKER"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    while true; do
        echo -e "${azul}📛 Ingresa un nombre para la imagen Docker (Enter para usar 'gcp'):${neutro}"
        read -p "📝 Nombre de la imagen: " input_image
        IMAGE_NAME="${input_image:-gcp}"
        IMAGE_TAG="1.0"
        IMAGE_PATH="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME"
        IMAGE_FULL="$IMAGE_PATH:$IMAGE_TAG"

        echo -e "${azul}🔍 Comprobando si la imagen '${IMAGE_NAME}:${IMAGE_TAG}' ya existe...${neutro}"

        if gcloud artifacts docker images describe "$IMAGE_FULL" &>/dev/null; then
            echo -e "${rojo}❌ Ya existe una imagen '${IMAGE_NAME}:${IMAGE_TAG}' en el repositorio.${neutro}"
            echo -e "${amarillo}🔁 Por favor, elige un nombre diferente para evitar sobrescribir.${neutro}"
            continue
        else
            echo -e "${verde}✔ Nombre de imagen válido y único.${neutro}"
            break
        fi
    done

    echo -e "${cyan}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📥 CLONANDO REPOSITORIO"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ -d "sshws-gcp" ]]; then
        echo -e "${amarillo}🧹 Eliminando versión previa del directorio sshws-gcp...${neutro}"
        rm -rf sshws-gcp
    fi

    git clone https://github.com/ChristopherAGT/sshws-gcp || {
        echo -e "${rojo}❌ Error al clonar el repositorio.${neutro}"
        exit 1
    }

    cd sshws-gcp || {
        echo -e "${rojo}❌ No se pudo acceder al directorio sshws-gcp.${neutro}"
        exit 1
    }

    echo -e "${cyan}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐳 CONSTRUYENDO IMAGEN DOCKER"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker build -t "$IMAGE_PATH:$IMAGE_TAG" .

    [[ $? -ne 0 ]] && echo -e "${rojo}❌ Error al construir la imagen.${neutro}" && exit 1

    echo -e "${cyan}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📤 SUBIENDO IMAGEN A ARTIFACT REGISTRY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker push "$IMAGE_PATH:$IMAGE_TAG"

    [[ $? -ne 0 ]] && echo -e "${rojo}❌ Error al subir la imagen.${neutro}" && exit 1

    echo -e "${cyan}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧹 LIMPIANDO DIRECTORIO TEMPORAL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cd ..
    rm -rf sshws-gcp

    echo -e "${amarillo}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║ ✅ Imagen '$IMAGE_NAME:$IMAGE_TAG' subida exitosamente.       ║"
    echo "║ 📍 Ruta: $IMAGE_PATH:$IMAGE_TAG"
    echo "╚════════════════════════════════════════════════════════════╝"
fi
  
# 🚀 DESPLIEGUE DEL SERVICIO EN CLOUD RUN
echo -e "${cyan}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 DESPLEGANDO SERVICIO EN CLOUD RUN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

# 🌍 SELECCIÓN DE REGIÓN PARA CLOUD RUN
echo -e "${cyan}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌍 SELECCIÓN DE REGIÓN PARA DESPLEGAR CLOUD RUN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${neutro}"

for i in "${!REGIONS[@]}"; do
  printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

while true; do
  read -p "Ingrese el número de la región para el servicio: " CLOUD_RUN_INDEX

  if ! [[ "$CLOUD_RUN_INDEX" =~ ^[0-9]+$ ]] || (( CLOUD_RUN_INDEX < 1 || CLOUD_RUN_INDEX > ${#REGION_CODES[@]} )); then
    echo -e "${rojo}❌ Selección inválida. Intente nuevamente.${neutro}"
  else
    CLOUD_RUN_REGION=${REGION_CODES[$((CLOUD_RUN_INDEX-1))]}
    echo -e "${verde}✔ Región seleccionada para Cloud Run: $CLOUD_RUN_REGION${neutro}"
    break
  fi
done

# Solicitar al usuario el nombre del servicio (default: rain)
read -p "📛 Ingresa el nombre que deseas para el servicio en Cloud Run (default: rain): " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-rain}

# 🔐 Solicitar y validar el subdominio personalizado para DHOST
while true; do
    echo -e "${amarillo}"
    read -p "🌐 Ingrese su subdominio personalizado (Cloudflare): " DHOST
    echo -e "${neutro}"

    # Validar que no esté vacío, tenga al menos un punto, y no tenga espacios
    if [[ -z "$DHOST" || "$DHOST" != *.* || "$DHOST" == *" "* ]]; then
        echo -e "${rojo}❌ El subdominio no puede estar vacío, debe contener al menos un punto y no tener espacios.${neutro}"
        continue
    fi

    echo -e "${verde}✅ Se ingresó el subdominio: $DHOST${neutro}"
    echo
    echo -ne "${cyan}¿Desea continuar con este subdominio? (s/n): ${neutro}"
    read -r CONFIRMAR
    CONFIRMAR=${CONFIRMAR,,}

    if [[ "$CONFIRMAR" == "s" ]]; then
        break
    else
        echo -e "${azul}🔁 Vamos a volver a solicitar el subdominio...${neutro}"
    fi
done

# Obtener número de proyecto
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")

# Ejecutar despliegue en la región seleccionada
SERVICE_URL=$(gcloud run deploy "$SERVICE_NAME" \
  --image "$IMAGE_PATH:$IMAGE_TAG" \
  --platform managed \
  --region "$CLOUD_RUN_REGION" \
  --allow-unauthenticated \
  --port 8080 \
  --timeout 3600 \
  --concurrency 100 \
  --set-env-vars="DHOST=${DHOST},DPORT=22" \
  --quiet \
  --format="value(status.url)")

# Verificar éxito del despliegue
if [[ $? -ne 0 ]]; then
    echo -e "${rojo}❌ Error en el despliegue de Cloud Run.${neutro}"
    exit 1
fi

# Dominio regional del servicio
REGIONAL_DOMAIN="https://${SERVICE_NAME}-${PROJECT_NUMBER}.${CLOUD_RUN_REGION}.run.app"

# Mostrar resumen final
echo -e "${verde}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ 📦 INFORMACIÓN DEL DESPLIEGUE EN CLOUD RUN                  ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║ 🗂️ ID del Proyecto GCP  : $PROJECT_ID"
echo "║ 🔢 Número de Proyecto   : $PROJECT_NUMBER"
echo "║ 🗃️ Repositorio Docker   : $REPO_NAME"
echo "║ 📍 Región de Despliegue : $REGION"
echo "║ 🖼️ Nombre de la Imagen  : $IMAGE_NAME:$IMAGE_TAG"
echo "║ 📛 Nombre del Servicio  : $SERVICE_NAME"
echo "║ 📍 Región de Despliegue : $CLOUD_RUN_REGION"
echo "║ 🌐 URL del Servicio     : $SERVICE_URL"
echo "║ 🌐 Dominio Regional     : $REGIONAL_DOMAIN"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${neutro}"
