#!/usr/bin/env bash

INPUT_DIR="/home/Reneto/.emulationstation/themes/iisu-esx/_inc/logos"
OUTPUT_DIR="/home/Reneto/.emulationstation/themes/iisu-esx/_inc/logos/ovalar_salida"

mkdir -p "$OUTPUT_DIR"
shopt -s nullglob

if command -v magick >/dev/null 2>&1; then
    IM_CMD="magick"
elif command -v convert >/dev/null 2>&1; then
    IM_CMD="convert"
else
    echo "Error: no se encontró ImageMagick."
    exit 1
fi

if command -v identify >/dev/null 2>&1; then
    ID_CMD="identify"
else
    echo "Error: no se encontró 'identify'."
    exit 1
fi

for img in "$INPUT_DIR"/*.png; do
    filename="$(basename "$img")"

    width="$($ID_CMD -format "%w" "$img")"
    height="$($ID_CMD -format "%h" "$img")"

    if [ -z "$width" ] || [ -z "$height" ]; then
        echo "Error al leer tamaño: $filename"
        continue
    fi

    x2=$((width - 1))
    y2=$((height - 1))

    # radio de esquina: 20% del lado
    rx=$((width / 5))
    ry=$((height / 5))

    "$IM_CMD" "$img" \
        \( -size "${width}x${height}" xc:black \
           -fill white \
           -draw "roundrectangle 0,0 ${x2},${y2} ${rx},${ry}" \
        \) \
        -alpha off \
        -compose copy_opacity \
        -composite \
        "$OUTPUT_DIR/$filename"

    if [ $? -eq 0 ]; then
        echo "Procesado: $filename"
    else
        echo "Error al procesar: $filename"
    fi
done

echo "Listo. Archivos guardados en: $OUTPUT_DIR"