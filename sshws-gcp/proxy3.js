/*
 * Proxy Bridge 2.0
 * Autor: ChristopherAGT - Guatemalteco
 */

const crypto = require("crypto");
const net = require("net");
const fs = require("fs");

// =======================
// Configuración inicial
// =======================
let dhost = process.env.DHOST || "127.0.0.1";
let dport = parseInt(process.env.DPORT, 10) || 40000;
let mainPort = parseInt(process.env.PORT, 10) || 8080;
let outputFile = null;
let packetsToSkip = parseInt(process.env.PACKSKIP, 10) || 1;
let gcwarn = true;

// =======================
// Argumentos por consola
// =======================
for (let i = 0; i < process.argv.length; i++) {
    switch (process.argv[i]) {
        case "-skip":
            packetsToSkip = parseInt(process.argv[i + 1], 10) || packetsToSkip;
            break;
        case "-dhost":
            dhost = process.argv[i + 1] || dhost;
            break;
        case "-dport":
            dport = parseInt(process.argv[i + 1], 10) || dport;
            break;
        case "-mport":
            mainPort = parseInt(process.argv[i + 1], 10) || mainPort;
            break;
        case "-o":
            outputFile = process.argv[i + 1] || null;
            break;
    }
}

// =========================
// Recolección de basura
// =========================
function gcollector() {
    if (!global.gc && gcwarn) {
        console.warn("[WARNING] Garbage Collector isn't enabled! Run with --expose-gc");
        gcwarn = false;
        return;
    }
    if (global.gc) {
        global.gc();
    }
}
setInterval(gcollector, 1000);

// ==============================
// Limpieza de IP tipo "::ffff:"
// ==============================
function parseRemoteAddr(raddr) {
    const strAddr = raddr.toString();
    return strAddr.includes("ffff") ? strAddr.substring(strAddr.indexOf("ffff") + 4) : strAddr;
}

// =====================
// Crear servidor TCP
// =====================
const server = net.createServer();

server.on("connection", (socket) => {
    let packetCount = 0;
    const clientIP = parseRemoteAddr(socket.remoteAddress);
    const clientPort = socket.remotePort;

    // Simula handshake WebSocket falso
    const wsAccept = Buffer.from(crypto.randomBytes(20)).toString("base64");
    socket.write(
        `HTTP/1.1 101 Switching Protocols\r\n` +
        `Connection: Upgrade\r\n` +
        `Date: ${new Date().toUTCString()}\r\n` +
        `Sec-WebSocket-Accept: ${wsAccept}\r\n` +
        `Upgrade: websocket\r\n` +
        `Server: p7ws/0.1a\r\n\r\n`
    );

    console.log(`[INFO] New connection from ${clientIP}:${clientPort}`);

    const conn = net.createConnection({ host: dhost, port: dport });

    // Cliente → Proxy → Destino
    socket.on("data", (data) => {
        if (packetCount++ >= packetsToSkip) {
            conn.write(data);
            if (outputFile) {
                fs.appendFileSync(outputFile, `[CLIENT -> DEST] ${data.toString("hex")}\n`);
            }
        }
    });

    // Destino → Proxy → Cliente
    conn.on("data", (data) => {
        socket.write(data);
        if (outputFile) {
            fs.appendFileSync(outputFile, `[DEST -> CLIENT] ${data.toString("hex")}\n`);
        }
    });

    // Errores y limpieza
    const closeBoth = () => {
        socket.destroy();
        conn.destroy();
    };

    socket.on("error", (err) => {
        console.error(`[SOCKET ERROR] ${clientIP}:${clientPort} - ${err.message}`);
        closeBoth();
    });

    conn.on("error", (err) => {
        console.error(`[REMOTE ERROR] ${dhost}:${dport} - ${err.message}`);
        closeBoth();
    });

    socket.on("close", () => {
        console.log(`[INFO] Connection closed ${clientIP}:${clientPort}`);
        conn.end();
    });

    conn.on("close", () => {
        socket.end();
    });
});

server.listen(mainPort, () => {
    console.log(`[INFO] Proxy server running on port ${mainPort}`);
    console.log(`[INFO] Forwarding to ${dhost}:${dport}`);
    if (outputFile) console.log(`[INFO] Logging traffic to ${outputFile}`);
});
