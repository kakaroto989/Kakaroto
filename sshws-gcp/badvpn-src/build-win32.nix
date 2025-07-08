# build-win32.nix - Construye BadVPN para Windows (Win32) mediante compilación cruzada con MinGW
# NOTA: Este archivo debe usarse con una versión modificada de nixpkgs:
# https://github.com/ambrop72/nixpkgs/tree/cross-mingw-nss

let
  # Función que importa nixpkgs desde el canal por defecto
  pkgsFun = import <nixpkgs>;

  # Definición del sistema destino (cross-compilation target)
  crossSystem = {
    config = "i686-w64-mingw32";  # Target triple para MinGW de 32 bits
    arch = "x86";                 # Arquitectura de 32 bits
    libc = "msvcrt";              # Librería C usada en Windows
    platform = {};
    openssl.system = "mingw";    # Especifica que OpenSSL debe compilarse para MinGW
    is64bit = false;             # Sistema de 32 bits
  };

  # Importa nixpkgs con soporte para compilación cruzada
  pkgs = pkgsFun {
    inherit crossSystem;
  };

in
with pkgs;

rec {
  inherit pkgs;

  # Importa la función que define los paquetes de BadVPN para Win32
  badvpnPkgsFunc = import ./badvpn-win32.nix;

  # Construcción normal (release)
  badvpnPkgs = callPackage badvpnPkgsFunc {};

  # Construcción con depuración activada
  badvpnDebugPkgs = callPackage badvpnPkgsFunc { debug = true; };
}
