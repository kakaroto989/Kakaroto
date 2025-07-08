# Archivo de construcción para BadVPN para Windows (32 bits) usando Nix

{ stdenv, cmake, pkgconfig, openssl, nspr, nss, zlib, sqlite, zip, debug ? false }:

rec {
  # Derivación principal: compila BadVPN para Windows
  badvpn = (
    let
      # Flags de compilación: -O3 para optimización, -DNDEBUG si no estamos en modo debug
      compileFlags = "-O3 ${stdenv.lib.optionalString (!debug) "-DNDEBUG"}";
    in
    stdenv.mkDerivation {
      name = "badvpn";
      src = stdenv.lib.cleanSource ./.;

      # Dependencias para la configuración y compilación
      nativeBuildInputs = [ cmake pkgconfig ];
      buildInputs = [ openssl nspr nss ];

      # Flags para el compilador (includes y debug symbols)
      NIX_CFLAGS_COMPILE = "-I${nspr.crossDrv.dev}/include/nspr -I${nss.crossDrv.dev}/include/nss -ggdb";
      NIX_CFLAGS_LINK = [ "-ggdb" ];

      # Configuración previa al paso de configuración (cross-compiling para Windows)
      preConfigure = ''
        cmakeFlagsArray=(
          "-DCMAKE_BUILD_TYPE="
          "-DCMAKE_C_FLAGS=${compileFlags}"
          "-DCMAKE_SYSTEM_NAME=Windows"
        );
      '';

      # Post-instalación: copia los DLL necesarios al directorio binario
      postInstall = ''
        # Copiar DLLs de OpenSSL
        for lib in eay32; do
          cp ${openssl.crossDrv.bin}/bin/lib$lib.dll $out/bin/
        done

        # Copiar DLLs de NSPR
        for lib in nspr4 plc4 plds4; do
          cp ${nspr.crossDrv.out}/lib/lib$lib.dll $out/bin/
        done

        # Copiar DLLs de NSS
        for lib in nss3 nssutil3 smime3 ssl3 softokn3 freebl3; do
          cp ${nss.crossDrv.out}/lib/$lib.dll $out/bin/
        done

        # Copiar zlib y SQLite DLLs
        cp ${zlib.crossDrv.out}/bin/zlib1.dll $out/bin/
        cp ${sqlite.crossDrv.out}/bin/libsqlite3-0.dll $out/bin/

        # Función dummy para enlazar DLLs (no hace nada)
        _linkDLLs() { true; }
      '';

      # Evita eliminar símbolos de depuración al cruzar compilación
      dontCrossStrip = true;
    }
  ).crossDrv;

  # Derivación para empaquetar BadVPN en un archivo ZIP
  badvpnZip = stdenv.mkDerivation {
    name = "badvpn.zip";
    unpackPhase = "true"; # No hay fuentes que desempaquetar

    nativeBuildInputs = [ zip ];

    installPhase = ''
      mkdir badvpn-win32
      ln -s ${badvpn}/bin badvpn-win32/bin

      # Empaquetar en un archivo ZIP
      zip -q -r $out badvpn-win32
    '';
  };
}
