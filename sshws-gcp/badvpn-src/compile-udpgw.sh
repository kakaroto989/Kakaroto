#!/usr/bin/env bash
#
# Compila udpgw para Linux sin usar CMake.
# Uso previsto como alternativa rápida si no se quiere lidiar con CMake.
#
# Variables de entorno esperadas:
#   SRCDIR  - Ruta al código fuente de BadVPN (debe contener CMakeLists.txt)
#   CC      - Compilador (por ejemplo, gcc o clang)
#   CFLAGS  - Flags para compilación
#   LDFLAGS - Flags para enlazado
#   ENDIAN  - "little" o "big"
#   KERNEL  - "2.6" (por defecto) o "2.4"
#
# Archivos generados: objetos y ejecutable "udpgw" en el directorio actual.
#

set -e  # Salir al primer error
set -x  # Imprimir comandos conforme se ejecutan (debug)

# Validación de SRCDIR
if [[ -z $SRCDIR ]] || [[ ! -e $SRCDIR/CMakeLists.txt ]]; then
    echo "Error: SRCDIR no está definido o no contiene CMakeLists.txt"
    exit 1
fi

# Validación de CC (compilador)
if ! "${CC}" --version &>/dev/null; then
    echo "Error: CC no es un compilador válido"
    exit 1
fi

# Validación de ENDIAN
if [[ $ENDIAN != "little" ]] && [[ $ENDIAN != "big" ]]; then
    echo "Error: ENDIAN debe ser 'little' o 'big'"
    exit 1
fi

# Validación de KERNEL
if [[ -z $KERNEL ]]; then
    KERNEL="2.6"
elif [[ $KERNEL != "2.6" && $KERNEL != "2.4" ]]; then
    echo "Error: KERNEL debe ser '2.6' o '2.4'"
    exit 1
fi

# Asegurar compatibilidad con C99
CFLAGS="${CFLAGS} -std=gnu99"

# Incluir directorios de cabecera
INCLUDES=( "-I${SRCDIR}" )

# Definiciones de preprocesador comunes
DEFS=(
    -DBADVPN_THREAD_SAFE=0
    -DBADVPN_LINUX
    -DBADVPN_BREACTOR_BADVPN
    -D_GNU_SOURCE
)

# Definiciones específicas según el kernel
if [[ $KERNEL == "2.4" ]]; then
    DEFS+=( -DBADVPN_USE_SELFPIPE -DBADVPN_USE_POLL )
else
    DEFS+=( -DBADVPN_USE_SIGNALFD -DBADVPN_USE_EPOLL )
fi

# Definición de endianness
if [[ $ENDIAN == "little" ]]; then
    DEFS+=( -DBADVPN_LITTLE_ENDIAN )
else
    DEFS+=( -DBADVPN_BIG_ENDIAN )
fi

# Lista de archivos fuente
SOURCES="
base/BLog_syslog.c
system/BReactor_badvpn.c
system/BSignal.c
system/BConnection_unix.c
system/BConnection_common.c
system/BDatagram_unix.c
system/BTime.c
system/BUnixSignal.c
system/BNetwork.c
flow/StreamRecvInterface.c
flow/PacketRecvInterface.c
flow/PacketPassInterface.c
flow/StreamPassInterface.c
flow/SinglePacketBuffer.c
flow/BufferWriter.c
flow/PacketBuffer.c
flow/PacketStreamSender.c
flow/PacketProtoFlow.c
flow/PacketPassFairQueue.c
flow/PacketProtoEncoder.c
flow/PacketProtoDecoder.c
base/DebugObject.c
base/BLog.c
base/BPending.c
udpgw/udpgw.c
"

# Compilar cada archivo fuente en un objeto
OBJS=()
for f in $SOURCES; do
    obj=$(basename "${f}").o
    "${CC}" -c ${CFLAGS} "${INCLUDES[@]}" "${DEFS[@]}" "${SRCDIR}/${f}" -o "${obj}"
    OBJS+=( "${obj}" )
done

# Enlazar objetos en ejecutable final
"${CC}" ${LDFLAGS} "${OBJS[@]}" -o udpgw -lrt -lpthread
