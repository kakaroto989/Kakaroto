{ stdenv, cmake, pkgconfig, openssl, nspr, nss, debug ? false }:

let
  # Definimos los flags de compilación.
  # -O3 para optimización máxima.
  # Si `debug` es falso, agregamos -DNDEBUG para deshabilitar los asserts.
  compileFlags = "-O3 ${stdenv.lib.optionalString (!debug) "-DNDEBUG"}";
in

stdenv.mkDerivation {
  name = "badvpn";  # Nombre del paquete resultante.

  # Herramientas necesarias solo durante la compilación (no en tiempo de ejecución).
  nativeBuildInputs = [ cmake pkgconfig ];

  # Dependencias necesarias tanto para compilar como para ejecutar.
  buildInputs = [ openssl nspr nss ];

  # Fuente del código, limpiada para excluir archivos no relevantes.
  src = stdenv.lib.cleanSource ./.;

  # Se ejecuta antes de configurar con CMake.
  # Establece las opciones para el generador (build type vacío, y CFLAGS personalizados).
  preConfigure = ''
    cmakeFlagsArray=( "-DCMAKE_BUILD_TYPE=" "-DCMAKE_C_FLAGS=${compileFlags}" );
  '';
}
