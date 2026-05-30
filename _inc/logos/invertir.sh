#!/usr/bin/env bash

# Generador simple:
# Toma cada PNG y lo convierte en una card completa.
# La imagen ocupa todo el interior, con esquinas redondeadas,
# borde azul/violeta y pestaña ES.

set -u

SRC_DIR="/home/Reneto/.emulationstation/logos"
OUT_DIR="/home/Reneto/.emulationstation/logos_cards_borde"

SIZE=1024
PAD=26
INNER_SIZE=$((SIZE - PAD * 2))
OUTER_CORNER=78
INNER_CORNER=54

TMP="/tmp/cards_borde_$$"

mkdir -p "$OUT_DIR"
mkdir -p "$TMP"

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT

FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
if [ ! -f "$FONT" ]; then
    FONT="DejaVu-Sans-Bold"
fi

if ! command -v convert >/dev/null 2>&1; then
    echo "ERROR: ImageMagick no está instalado."
    echo "Instalá con:"
    echo "sudo apt install imagemagick"
    exit 1
fi

echo "=========================================="
echo " Generador de cards con borde ES-X"
echo "=========================================="
echo "Origen : $SRC_DIR"
echo "Salida : $OUT_DIR"
echo ""

# ------------------------------------------------------------
# Máscara exterior redondeada
# ------------------------------------------------------------
convert -size ${SIZE}x${SIZE} xc:none \
    -fill white \
    -draw "roundrectangle 0,0 $((SIZE-1)),$((SIZE-1)) $OUTER_CORNER,$OUTER_CORNER" \
    "$TMP/outer_mask.png"

# ------------------------------------------------------------
# Borde exterior degradado
# ------------------------------------------------------------
convert -size ${SIZE}x${SIZE} gradient:"#09b5e8-#8c26ff" \
    "$TMP/outer_gradient.png"

convert "$TMP/outer_gradient.png" "$TMP/outer_mask.png" \
    -alpha off -compose CopyOpacity -composite \
    "$TMP/outer.png"

# ------------------------------------------------------------
# Máscara interior redondeada
# ------------------------------------------------------------
convert -size ${INNER_SIZE}x${INNER_SIZE} xc:none \
    -fill white \
    -draw "roundrectangle 0,0 $((INNER_SIZE-1)),$((INNER_SIZE-1)) $INNER_CORNER,$INNER_CORNER" \
    "$TMP/inner_mask.png"

# ------------------------------------------------------------
# Pestaña ES redondeada
# ------------------------------------------------------------
convert -size ${SIZE}x${SIZE} xc:none \
    -fill "#14b4ea" \
    -draw "path 'M 0,0 L 180,0 L 180,100 C 180,145 145,180 100,180 L 0,180 Z'" \
    "$TMP/es_tab.png"

convert "$TMP/es_tab.png" \
    -font "$FONT" \
    -fill white \
    -pointsize 72 \
    -gravity northwest \
    -annotate +42+63 "ES" \
    "$TMP/es_tab_text.png"

# ------------------------------------------------------------
# Procesar logos
# ------------------------------------------------------------
shopt -s nullglob

TOTAL=0
OK=0
FAIL=0

for SRC in "$SRC_DIR"/*.png; do
    FILE="$(basename "$SRC")"
    NAME="${FILE%.*}"

    TOTAL=$((TOTAL+1))
    echo "Procesando: $FILE"

    WORK="$TMP/$NAME"
    mkdir -p "$WORK"

    # La imagen ocupa todo el interior.
    # El ^ hace crop tipo cover: llena el cuadro sin dejar bordes.
    if ! convert "$SRC" \
        -background "#171414" \
        -alpha remove \
        -alpha off \
        -resize ${INNER_SIZE}x${INNER_SIZE}^ \
        -gravity center \
        -extent ${INNER_SIZE}x${INNER_SIZE} \
        "$WORK/content.png"; then

        echo "  ERROR preparando: $FILE"
        FAIL=$((FAIL+1))
        continue
    fi

    # Aplicar esquinas redondeadas al contenido.
    convert "$WORK/content.png" "$TMP/inner_mask.png" \
        -alpha off -compose CopyOpacity -composite \
        "$WORK/content_round.png"

    # Composición final.
        if convert -size ${SIZE}x${SIZE} xc:none \
        "$TMP/outer.png" -compose over -composite \
        "$WORK/content_round.png" -gravity center -compose over -composite \
        "$TMP/es_tab_text.png" -compose over -composite \
        "$TMP/outer_mask.png" -alpha off -compose CopyOpacity -composite \
        "$OUT_DIR/$FILE"; then

        OK=$((OK+1))
    else
        echo "  ERROR generando: $FILE"
        FAIL=$((FAIL+1))
    fi
done

echo ""
echo "=========================================="
echo " Listo"
echo " Encontrados : $TOTAL"
echo " Generados   : $OK"
echo " Fallidos    : $FAIL"
echo " Carpeta     : $OUT_DIR"
echo "=========================================="