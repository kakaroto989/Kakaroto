# 🛠️ Compilación de BadVPN en Windows usando Visual Studio

Este documento describe el proceso para compilar BadVPN en Windows utilizando Visual Studio.  
🔹 **Nota:** Solo se ha probado la compilación de 32 bits, y es la que se describe aquí.

---

## 🔧 Requisitos Previos

### 🧰 Visual Studio

Debes tener instalado **Visual Studio 2017**.

### 🧱 CMake

Instala **CMake** (preferiblemente la versión más reciente).

### 🔐 OpenSSL (opcional)

**Solo necesario si necesitas funciones más allá de `tun2socks` o `udpgw`** (es decir, si no es únicamente para software VPN).

1. Instala **ActivePerl** si aún no lo tienes.
2. Descarga y extrae el código fuente de **OpenSSL**.
3. Abre un terminal de Visual Studio x86 Native Tools (ubicado en Programas -> Visual Studio 2017).
4. Entra en el directorio del código fuente de OpenSSL y ejecuta:

```bash
perl Configure VC-WIN32 no-asm --prefix=%cd%\install-dir
ms\do_ms
nmake -f ms\ntdll.mak install
```

---

### 🔐 NSS (opcional)

**Solo necesario si necesitas funciones más allá de `tun2socks` o `udpgw`**.

1. Instala **MozillaBuild** desde: https://wiki.mozilla.org/MozillaBuild  
2. Descarga y extrae el código fuente de **NSS con NSPR** (`nss-VERSION-with-nspr-VERSION.tar.gz`).
3. Copia `C:\mozilla-build\start-shell.bat` a `C:\mozilla-build\start-shell-fixed.bat`.
4. Edita `start-shell-fixed.bat` y **elimina** las siguientes líneas al inicio del archivo:

```batch
SET INCLUDE=
SET LIB=
IF NOT DEFINED MOZ_NO_RESET_PATH (
  SET PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem
)
```

5. Abre un terminal de Visual Studio x86 Native Tools.
6. Lanza la shell de MozillaBuild:

```bash
C:\mozilla-build\start-shell-fixed.bat
```

7. Dentro de la shell, entra en el directorio fuente de NSS y ejecuta:

```bash
make -C nss nss_build_all OS_TARGET=WINNT BUILD_OPT=1
cp -r dist/private/. dist/public/. dist/WINNT*.OBJ/include/
```

---

## 🏗️ Compilación de BadVPN

1. Abre un terminal de Visual Studio x86 Native Tools.
2. Entra en el directorio del código fuente de **BadVPN**.
3. Si compilaste **OpenSSL** y/o **NSS**, define la ruta a estas bibliotecas con `CMAKE_PREFIX_PATH`:

```batch
set CMAKE_PREFIX_PATH=<openssl-source-dir>\install-dir;<nss-source-dir>\dist\WINNT6.2_OPT.OBJ
```

💡 Asegúrate de que el nombre del directorio `.OBJ` es el correcto en tu caso.

4. Ejecuta los siguientes comandos para compilar BadVPN:

```bash
mkdir build
cd build
cmake .. -G "Visual Studio 15 2017" -DCMAKE_INSTALL_PREFIX=%cd%\..\install-dir
cmake --build . --config Release --target install
```

👉 Si **solo necesitas `tun2socks` y `udpgw`**, agrega estos flags al primer comando `cmake`:

```bash
-DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_TUN2SOCKS=1 -DBUILD_UDPGW=1
```

---

## 📦 Copiar Dependencias (si usaste OpenSSL/NSS)

Copia las bibliotecas necesarias a la carpeta de instalación para que los ejecutables puedan encontrarlas:

```batch
copy <openssl-source-dir>\install-dir\bin\libeay32.dll ..\install-dir\bin\
copy <nss-source-dir>\dist\WINNT6.2_OPT.OBJ\lib\*.dll ..\install-dir\bin\
```

---

## ✅ Resultado

La compilación finalizada estará disponible en:

```plaintext
<badvpn-source-dir>\install-dir
```

---

## ⚠️ Notas Adicionales

- Asegúrate de tener privilegios de administrador si encuentras errores de permisos durante la compilación.
- 📁 Las rutas deben ajustarse a tu entorno de desarrollo local.
