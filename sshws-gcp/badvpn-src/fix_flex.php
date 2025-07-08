<?php

// Verifica que se haya pasado un archivo como argumento
if ($argc < 2) {
    fwrite(STDERR, "Uso: php fix_flex.php <archivo>\n");
    exit(1);
}

$filename = $argv[1];

// Lee el contenido del archivo
$contents = file_get_contents($filename);
if ($contents === false) {
    fwrite(STDERR, "Error: no se pudo leer el archivo '$filename'\n");
    exit(1);
}

// Reemplaza <inttypes.h> con <stdint.h>
// y una condición específica con "#if 1" para simplificar compatibilidad
$search = [
    "<inttypes.h>",
    "#if defined (__STDC_VERSION__) && __STDC_VERSION__ >= 199901L"
];

$replace = [
    "<stdint.h>",
    "#if 1"
];

$contents = str_replace($search, $replace, $contents);

// Escribe el contenido modificado de nuevo al archivo
$res = file_put_contents($filename, $contents);
if ($res === false) {
    fwrite(STDERR, "Error: no se pudo escribir al archivo '$filename'\n");
    exit(1);
}
