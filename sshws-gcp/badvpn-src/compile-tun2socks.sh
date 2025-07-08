#!/usr/bin/env bash
#
# Compila tun2socks para Linux sin usar CMake.
# Útil si se desea evitar la configuración de CMake.
#
# Variables de entorno esperadas:
#   SRCDIR  - Directorio del código fuente de BadVPN (debe contener CMakeLists.txt)
#   OUTDIR  - Directorio de salida del binario tun2socks
#   CC      - Compilador (ej. gcc o clang)
#   CFLAGS  - Flags de compilación
#   LDFLAGS - Flags de enlazado
#   ENDIAN  - "little" o "big"
#   KERNEL  - "2.6" o "2.4" (por defecto: "2.6")
#
# Resultado: ejecutable tun2socks y archivos .o en el directorio actual.
#

set -e  # Detener ejecución ante errores
set -x  # Mostrar cada comando ejecutado (modo debug)

# Validación del directorio fuente
if [[ -z $SRCDIR ]] || [[ ! -e $SRCDIR/CMakeLists.txt ]]; then
    echo "Error: SRCDIR no está definido o no contiene CMakeLists.txt"
    exit 1
fi

# Validación del directorio de salida (si está definido)
if [[ -n $OUTDIR ]] && [[ ! -d $OUTDIR ]]; then
    echo "Error: OUTDIR no existe o no es un directorio"
    exit 1
fi

# Validación del compilador
if ! "${CC}" --version &>/dev/null; then
    echo "Error: CC no es un compilador válido"
    exit 1
fi

# Validación de endianness
if [[ $ENDIAN != "little" && $ENDIAN != "big" ]]; then
    echo "Error: ENDIAN debe ser 'little' o 'big'"
    exit 1
fi

# Validación de kernel (por defecto 2.6)
if [[ -z $KERNEL ]]; then
    KERNEL="2.6"
elif [[ $KERNEL != "2.6" && $KERNEL != "2.4" ]]; then
    echo "Error: KERNEL debe ser '2.6' o '2.4'"
    exit 1
fi

# Añadir compatibilidad con C99
CFLAGS="${CFLAGS} -std=gnu99"

# Rutas de inclusión
INCLUDES=(
    "-I${SRCDIR}"
    "-I${SRCDIR}/lwip/src/include/ipv4"
    "-I${SRCDIR}/lwip/src/include/ipv6"
    "-I${SRCDIR}/lwip/src/include"
    "-I${SRCDIR}/lwip/custom"
)

# Definiciones comunes de preprocesador
DEFS=(
    -DBADVPN_THREAD_SAFE=0
    -DBADVPN_LINUX
    -DBADVPN_BREACTOR_BADVPN
    -D_GNU_SOURCE
)

# Definiciones según kernel
if [[ $KERNEL == "2.4" ]]; then
    DEFS+=( -DBADVPN_USE_SELFPIPE -DBADVPN_USE_POLL )
else
    DEFS+=( -DBADVPN_USE_SIGNALFD -DBADVPN_USE_EPOLL )
fi

# Definiciones según endianness
if [[ $ENDIAN == "little" ]]; then
    DEFS+=( -DBADVPN_LITTLE_ENDIAN )
else
    DEFS+=( -DBADVPN_BIG_ENDIAN )
fi

# Usar el directorio actual si OUTDIR no está definido
[[ -z $OUTDIR ]] && OUTDIR="."

# Lista de archivos fuente (se conserva 100% igual)
SOURCES="
base/BLog_syslog.c
system/BReactor_badvpn.c
system/BSignal.c
system/BConnection_unix.c
system/BConnection_common.c
system/BTime.c
system/BUnixSignal.c
system/BNetwork.c
system/BDatagram_common.c
system/BDatagram_unix.c
flow/StreamRecvInterface.c
flow/PacketRecvInterface.c
flow/PacketPassInterface.c
flow/StreamPassInterface.c
flow/SinglePacketBuffer.c
flow/BufferWriter.c
flow/PacketBuffer.c
flow/PacketStreamSender.c
flow/PacketPassConnector.c
flow/PacketProtoFlow.c
flow/PacketPassFairQueue.c
flow/PacketProtoEncoder.c
flow/PacketProtoDecoder.c
socksclient/BSocksClient.c
tuntap/BTap.c
lwip/src/core/udp.c
lwip/src/core/memp.c
lwip/src/core/init.c
lwip/src/core/pbuf.c
lwip/src/core/tcp.c
lwip/src/core/tcp_out.c
lwip/src/core/sys.c
lwip/src/core/netif.c
lwip/src/core/def.c
lwip/src/core/mem.c
lwip/src/core/tcp_in.c
lwip/src/core/stats.c
lwip/src/core/ip.c
lwip/src/core/timeouts.c
lwip/src/core/inet_chksum.c
lwip/src/core/ipv4/icmp.c
lwip/src/core/ipv4/ip4.c
lwip/src/core/ipv4/ip4_addr.c
lwip/src/core/ipv4/ip4_frag.c
lwip/src/core/ipv6/ip6.c
lwip/src/core/ipv6/nd6.c
lwip/src/core/ipv6/icmp6.c
lwip/src/core/ipv6/ip6_addr.c
lwip/src/core/ipv6/ip6_frag.c
lwip/custom/sys.c
tun2socks/tun2socks.c
base/DebugObject.c
base/BLog.c
base/BPending.c
flowextra/PacketPassInactivityMonitor.c
tun2socks/SocksUdpGwClient.c
udpgw_client/UdpGwClient.c
socks_udp_client/SocksUdpClient.c
"

# Compilar cada archivo fuente en un archivo objeto .o
OBJS=()
for f in $SOURCES; do
    obj=${f//\//_}.o  # Reemplazar / por _ para nombre de archivo objeto
    "${CC}" -c ${CFLAGS} "${INCLUDES[@]}" "${DEFS[@]}" "${SRCDIR}/${f}" -o "${obj}"
    OBJS+=( "${obj}" )
done

# Enlazar todos los objetos en el binario final tun2socks
"${CC}" ${LDFLAGS} "${OBJS[@]}" -o "${OUTDIR}/tun2socks" -lrt -lpthread
