#!/bin/bash
#
# Script completo para extraer TODOS los dominios .bo
# Usa múltiples fuentes: crt.sh, VirusTotal, sublist3r, etc.
#

OUTPUT_FILE="dominios_bolivia_completo.txt"
TEMP_DIR="temp_dominios"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   Extractor COMPLETO de Dominios .bo                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Crear directorio temporal
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Limpiar archivo de salida
> "../$OUTPUT_FILE"

total_encontrados=0

# ============================================================
# FUENTE 1: crt.sh (Certificate Transparency)
# ============================================================
echo "[1] Extrayendo desde crt.sh..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v jq &> /dev/null; then
    curl -s "https://crt.sh/?q=%.bo&output=json" 2>/dev/null | \
        jq -r '.[].name_value' 2>/dev/null | \
        sed 's/\*\.//g' | \
        sort -u > crtsh.txt

    count=$(wc -l < crtsh.txt 2>/dev/null || echo 0)
    echo "  ✓ Encontrados desde crt.sh: $count dominios"
    ((total_encontrados+=count))
else
    # Sin jq, usar método alternativo
    curl -s "https://crt.sh/?q=%.bo" 2>/dev/null | \
        grep -oE '[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.bo' | \
        sed 's/\*\.//g' | \
        sort -u > crtsh.txt

    count=$(wc -l < crtsh.txt 2>/dev/null || echo 0)
    echo "  ✓ Encontrados desde crt.sh: $count dominios"
    ((total_encontrados+=count))
fi

# ============================================================
# FUENTE 2: Google (usando curl)
# ============================================================
echo ""
echo "[2] Extrayendo desde Google..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for i in {0..50..10}; do
    curl -s "https://www.google.com/search?q=site:.bo&start=$i" 2>/dev/null | \
        grep -oE '[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.bo' | \
        sort -u >> google.txt
    sleep 1
done

if [ -f google.txt ]; then
    sort -u google.txt -o google.txt
    count=$(wc -l < google.txt)
    echo "  ✓ Encontrados desde Google: $count dominios"
    ((total_encontrados+=count))
fi

# ============================================================
# FUENTE 3: Subfinder (si está instalado)
# ============================================================
echo ""
echo "[3] Extrayendo con Subfinder..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v subfinder &> /dev/null; then
    subfinder -d bo -silent -o subfinder.txt 2>/dev/null
    count=$(wc -l < subfinder.txt 2>/dev/null || echo 0)
    echo "  ✓ Encontrados con Subfinder: $count dominios"
    ((total_encontrados+=count))
else
    echo "  ⚠ Subfinder no instalado (opcional)"
fi

# ============================================================
# FUENTE 4: Assetfinder (si está instalado)
# ============================================================
echo ""
echo "[4] Extrayendo con Assetfinder..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v assetfinder &> /dev/null; then
    assetfinder --subs-only bo > assetfinder.txt 2>/dev/null
    count=$(wc -l < assetfinder.txt 2>/dev/null || echo 0)
    echo "  ✓ Encontrados con Assetfinder: $count dominios"
    ((total_encontrados+=count))
else
    echo "  ⚠ Assetfinder no instalado (opcional)"
fi

# ============================================================
# FUENTE 5: Amass (si está instalado)
# ============================================================
echo ""
echo "[5] Extrayendo con Amass..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v amass &> /dev/null; then
    timeout 60 amass enum -passive -d bo -o amass.txt 2>/dev/null
    count=$(wc -l < amass.txt 2>/dev/null || echo 0)
    echo "  ✓ Encontrados con Amass: $count dominios"
    ((total_encontrados+=count))
else
    echo "  ⚠ Amass no instalado (opcional)"
fi

# ============================================================
# Combinar y limpiar resultados
# ============================================================
echo ""
echo "[6] Combinando y limpiando resultados..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Combinar todos los archivos
cat *.txt 2>/dev/null | \
    grep -E '\.bo$' | \
    sed 's/\*\.//g' | \
    sed 's/^\.//g' | \
    tr '[:upper:]' '[:lower:]' | \
    sort -u > "../$OUTPUT_FILE"

# Volver al directorio anterior
cd ..

# Limpiar directorio temporal
rm -rf "$TEMP_DIR"

# Contar total único
total_unicos=$(wc -l < "$OUTPUT_FILE")

# ============================================================
# Resultados finales
# ============================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    RESULTADOS FINALES                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total de dominios únicos: $total_unicos"
echo "Archivo de salida: $OUTPUT_FILE"
echo ""

# Mostrar primeros 30 dominios
echo "Primeros 30 dominios encontrados:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
head -30 "$OUTPUT_FILE"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

# Estadísticas por TLD
echo "Dominios por tipo:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  .gob.bo: $(grep -c '\.gob\.bo$' "$OUTPUT_FILE")"
echo "  .com.bo: $(grep -c '\.com\.bo$' "$OUTPUT_FILE")"
echo "  .edu.bo: $(grep -c '\.edu\.bo$' "$OUTPUT_FILE")"
echo "  .org.bo: $(grep -c '\.org\.bo$' "$OUTPUT_FILE")"
echo "  .net.bo: $(grep -c '\.net\.bo$' "$OUTPUT_FILE")"
echo "  .bo: $(grep -cE '^[^.]+\.bo$' "$OUTPUT_FILE")"

echo ""
echo "✓ Extracción completada"
