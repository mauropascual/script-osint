#!/bin/bash
#
# Script para encontrar TODOS los endpoints de un dominio
# Usa múltiples herramientas: katana, waybackurls, gau, gospider, etc.
#

TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Uso: $0 <dominio>"
    echo "Ejemplo: $0 trabajito.com.bo"
    exit 1
fi

OUTPUT_DIR="endpoints_${TARGET//./_}"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Buscador de Endpoints - $TARGET"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Crear directorio
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

echo "🎯 Target: $TARGET"
echo "📁 Directorio: $OUTPUT_DIR"
echo ""

# ============================================================
# HERRAMIENTA 1: Katana
# ============================================================
echo "[1] Katana - Crawler moderno"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v katana &> /dev/null; then
    katana -u "https://$TARGET" \
        -d 5 \
        -jc \
        -f qurl \
        -ef woff,css,png,svg,jpg,woff2,jpeg,gif,svg,ico \
        -silent \
        -o katana_urls.txt 2>/dev/null

    count=$(wc -l < katana_urls.txt 2>/dev/null || echo 0)
    echo "  ✓ URLs encontradas: $count"
else
    echo "  ⚠ Katana no instalado"
fi
echo ""

# ============================================================
# HERRAMIENTA 2: waybackurls
# ============================================================
echo "[2] waybackurls - Archive.org"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v waybackurls &> /dev/null; then
    waybackurls "$TARGET" 2>/dev/null | sort -u > wayback_urls.txt
    count=$(wc -l < wayback_urls.txt 2>/dev/null || echo 0)
    echo "  ✓ URLs históricas: $count"
else
    echo "  ⚠ waybackurls no instalado"
fi
echo ""

# ============================================================
# HERRAMIENTA 3: gau (GetAllURLs)
# ============================================================
echo "[3] gau - URLs de múltiples fuentes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v gau &> /dev/null; then
    gau "$TARGET" 2>/dev/null | sort -u > gau_urls.txt
    count=$(wc -l < gau_urls.txt 2>/dev/null || echo 0)
    echo "  ✓ URLs encontradas: $count"
else
    echo "  ⚠ gau no instalado"
fi
echo ""

# ============================================================
# HERRAMIENTA 4: gospider
# ============================================================
echo "[4] gospider - Spider de Go"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v gospider &> /dev/null; then
    gospider -s "https://$TARGET" -d 3 -c 10 -t 20 -q 2>/dev/null | \
        grep -oE "https?://[^\s]+" | sort -u > gospider_urls.txt
    count=$(wc -l < gospider_urls.txt 2>/dev/null || echo 0)
    echo "  ✓ URLs encontradas: $count"
else
    echo "  ⚠ gospider no instalado"
fi
echo ""

# ============================================================
# HERRAMIENTA 5: hakrawler
# ============================================================
echo "[5] hakrawler - Crawler rápido"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v hakrawler &> /dev/null; then
    echo "https://$TARGET" | hakrawler -depth 3 -plain 2>/dev/null | \
        sort -u > hakrawler_urls.txt
    count=$(wc -l < hakrawler_urls.txt 2>/dev/null || echo 0)
    echo "  ✓ URLs encontradas: $count"
else
    echo "  ⚠ hakrawler no instalado"
fi
echo ""

# ============================================================
# Combinar todas las URLs
# ============================================================
echo "[6] Combinando resultados..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat *.txt 2>/dev/null | sort -u > all_urls.txt
total=$(wc -l < all_urls.txt)
echo "  ✓ Total URLs únicas: $total"
echo ""

# ============================================================
# Filtrar por categorías
# ============================================================
echo "[7] Clasificando endpoints..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Endpoints de API
grep -iE "(api|rest|graphql|v[0-9])" all_urls.txt | sort -u > api_endpoints.txt
echo "  ✓ Endpoints API: $(wc -l < api_endpoints.txt)"

# URLs con parámetros
grep "?" all_urls.txt | sort -u > urls_with_params.txt
echo "  ✓ URLs con parámetros: $(wc -l < urls_with_params.txt)"

# Archivos JavaScript
grep "\.js" all_urls.txt | grep -v "\.json" | sort -u > javascript_files.txt
echo "  ✓ Archivos JavaScript: $(wc -l < javascript_files.txt)"

# Archivos JSON
grep "\.json" all_urls.txt | sort -u > json_files.txt
echo "  ✓ Archivos JSON: $(wc -l < json_files.txt)"

# Archivos interesantes
grep -iE "\.(xml|txt|pdf|doc|docx|xls|xlsx|csv|sql|db|bak|zip|tar|gz|env|config)$" all_urls.txt | \
    sort -u > interesting_files.txt
echo "  ✓ Archivos interesantes: $(wc -l < interesting_files.txt)"

# Endpoints de admin/panel
grep -iE "(admin|panel|dashboard|login|auth)" all_urls.txt | sort -u > admin_endpoints.txt
echo "  ✓ Endpoints de admin: $(wc -l < admin_endpoints.txt)"

echo ""

# ============================================================
# Resultados finales
# ============================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    RESULTADOS FINALES                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "📊 Estadísticas:"
echo "  Total URLs: $total"
echo "  Endpoints API: $(wc -l < api_endpoints.txt)"
echo "  URLs con parámetros: $(wc -l < urls_with_params.txt)"
echo "  Archivos JavaScript: $(wc -l < javascript_files.txt)"
echo "  Archivos JSON: $(wc -l < json_files.txt)"
echo "  Archivos interesantes: $(wc -l < interesting_files.txt)"
echo "  Endpoints admin: $(wc -l < admin_endpoints.txt)"
echo ""

# Mostrar primeros resultados
echo "🔝 Top 15 endpoints de API:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
head -15 api_endpoints.txt

echo ""
echo "🔝 Archivos JavaScript:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
head -10 javascript_files.txt

echo ""
echo "🔝 Endpoints de admin:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat admin_endpoints.txt

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✅ Búsqueda completada"
echo "📁 Resultados en: $(pwd)"
echo ""

# Listar archivos generados
echo "📄 Archivos generados:"
ls -lh *.txt

echo ""
