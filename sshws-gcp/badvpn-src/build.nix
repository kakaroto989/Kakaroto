# build.nix - Expresión Nix para construir badvpn y su variante con debug

{ pkgs ? import <nixpkgs> {} }:  # Usa nixpkgs por defecto si no se proporciona

with pkgs;

rec {
  # Importa la función de construcción desde el archivo local 'badvpn.nix'.
  # Esta función debe retornar una derivación cuando se use con `callPackage`.
  badvpnFunc = import ./badvpn.nix;

  # Construye la versión normal (release) de BadVPN.
  badvpn = callPackage badvpnFunc {};

  # Construye una versión con soporte de depuración (debug).
  badvpnDebug = callPackage badvpnFunc { debug = true; };
}
