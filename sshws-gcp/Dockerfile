# ╔══════════════════════════════════════════════╗
# ║ 🛠️ ETAPA 1: COMPILACIÓN (BUILDER)           ║
# ╚══════════════════════════════════════════════╝
FROM alpine AS builder

# 📦 Instala herramientas necesarias para compilar BadVPN
RUN apk update && apk add --no-cache \
    gcc g++ cmake make linux-headers

# 📁 Directorio de trabajo
WORKDIR /workdir

# 👉 Copia solo los archivos necesarios para compilar
COPY badvpn-src/ ./badvpn-src

# ⚙️ Compila BadVPN con soporte TUN2SOCKS y UDPGW
WORKDIR /workdir/badvpn-src
RUN mkdir -p build
WORKDIR /workdir/badvpn-src/build
RUN cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1 -DBUILD_UDPGW=1 -DCMAKE_BUILD_TYPE=Release && \
    make -j2 install

# ╔══════════════════════════════════════════════╗
# ║ 🚀 ETAPA 2: EJECUCIÓN FINAL (RUNTIME)       ║
# ╚══════════════════════════════════════════════╝
FROM alpine

# 📦 Solo instala lo necesario para tiempo de ejecución
RUN apk update && apk add --no-cache \
    nodejs tmux dropbear bash

# 📁 Directorio principal de trabajo
WORKDIR /workdir

# 📂 Copia los binarios compilados desde el builder
COPY --from=builder /usr/local/bin /usr/local/bin

# 👉 Copia los archivos del proyecto (sin eliminar nada)
COPY proxy3.js ./
COPY run.sh ./
COPY badvpn-src/ ./badvpn-src
#COPY stunnel.conf /etc/stunnel

# 📂 Soporte opcional para stunnel (comentado)
#WORKDIR /etc/stunnel
#RUN apk add --no-cache openssl stunnel
#RUN openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=AR/ST=Tierra del Fuego/L=Usuahia/O=Common LLC/OU=Common LLC/CN=localhost"
#RUN cat key.pem cert.pem > stunnel.pem

# 👤 Usuario con shell restringida
RUN echo -e "/bin/false\n/usr/sbin/nologin\n" >> /etc/shells && \
    adduser -DH test -s /bin/false && \
    echo -e "test:qweasdzxc" | chpasswd

# ✅ Permisos al script principal
RUN chmod +x /workdir/run.sh

# 🚪 Puerto expuesto
EXPOSE 8080

# 🏁 Comando de inicio
#CMD ./run.sh [warning]
CMD [ "./run.sh" ]
