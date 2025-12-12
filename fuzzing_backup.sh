#!/bin/bash
#
# Script para fuzzing de directorios/archivos de backup
#

TARGET="$1"

if [ -z "$TARGET" ]; then
    TARGET="https://cain.aevivienda.gob.bo/backup/"
fi

OUTPUT_DIR="fuzzing_results_$(date +%Y%m%d_%H%M%S)"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Fuzzing de Directorios/Archivos de Backup                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

echo "🎯 Target: $TARGET"
echo "📁 Resultados en: $OUTPUT_DIR"
echo ""

# ============================================================
# Wordlists para backups
# ============================================================
echo "[1] Creando wordlists personalizadas..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Wordlist de nombres comunes de backup
cat > backup_names.txt << 'EOF'
backup
backups
bak
old
temp
tmp
archive
archives
db
database
dump
sql
backup_2024
backup_2023
backup_2022
backup_2021
backup_2020
site_backup
web_backup
db_backup
backup.zip
backup.tar.gz
backup.sql
backup.tar
backup.rar
backup.7z
copia
respaldo
EOF

# Wordlist de archivos específicos
cat > backup_files.txt << 'EOF'
backup
database
dump
export
site
web
www
public_html
httpdocs
data
users
clientes
empleados
cain
aevivienda
db
mysql
postgres
EOF

echo "  ✓ Wordlists creadas"
echo ""

# ============================================================
# FUZZING 1: ffuf - Archivos
# ============================================================
echo "[2] Fuzzing con ffuf - Archivos..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v ffuf &> /dev/null; then
    ffuf -w backup_files.txt \
         -u "${TARGET}FUZZ" \
         -e .zip,.tar.gz,.tar,.rar,.7z,.sql,.bak,.old,.txt,.gz,.tgz \
         -mc 200,301,302 \
         -c \
         -o ffuf_files.json \
         -of json \
         -s

    # Extraer URLs encontradas
    if [ -f ffuf_files.json ]; then
        jq -r '.results[].url' ffuf_files.json 2>/dev/null > found_files.txt
        count=$(wc -l < found_files.txt 2>/dev/null || echo 0)
        echo "  ✓ Archivos encontrados: $count"
    fi
else
    echo "  ⚠ ffuf no instalado"
fi
echo ""

# ============================================================
# FUZZING 2: ffuf - Directorios
# ============================================================
echo "[3] Fuzzing con ffuf - Directorios..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v ffuf &> /dev/null; then
    ffuf -w backup_names.txt \
         -u "${TARGET}FUZZ/" \
         -mc 200,301,302 \
         -c \
         -o ffuf_dirs.json \
         -of json \
         -s

    if [ -f ffuf_dirs.json ]; then
        jq -r '.results[].url' ffuf_dirs.json 2>/dev/null > found_dirs.txt
        count=$(wc -l < found_dirs.txt 2>/dev/null || echo 0)
        echo "  ✓ Directorios encontrados: $count"
    fi
else
    echo "  ⚠ ffuf no instalado"
fi
echo ""

# ============================================================
# FUZZING 3: gobuster
# ============================================================
echo "[4] Fuzzing con gobuster..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v gobuster &> /dev/null; then
    gobuster dir \
        -u "$TARGET" \
        -w backup_files.txt \
        -x zip,tar.gz,tar,rar,sql,bak,txt \
        -t 30 \
        -q \
        -o gobuster_results.txt 2>/dev/null

    if [ -f gobuster_results.txt ]; then
        count=$(grep -c "Status: 200" gobuster_results.txt 2>/dev/null || echo 0)
        echo "  ✓ Resultados: $count"
    fi
else
    echo "  ⚠ gobuster no instalado"
fi
echo ""

# ============================================================
# FUZZING 4: Archivos por año
# ============================================================
echo "[5] Fuzzing por año (2020-2024)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for year in {2020..2024}; do
    for month in {01..12}; do
        for file in backup db dump site; do
            url="${TARGET}${file}_${year}_${month}.zip"
            status=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 2)

            if [ "$status" = "200" ]; then
                echo "  ✓ $file_${year}_${month}.zip"
                echo "$url" >> found_by_date.txt
            fi
        done
    done
done

if [ -f found_by_date.txt ]; then
    count=$(wc -l < found_by_date.txt)
    echo "  ✓ Archivos por fecha: $count"
fi
echo ""

# ============================================================
# Combinar resultados
# ============================================================
echo "[6] Combinando todos los resultados..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat found_*.txt 2>/dev/null | sort -u > all_found.txt
total=$(wc -l < all_found.txt 2>/dev/null || echo 0)
echo "  ✓ Total único: $total"
echo ""

# ============================================================
# Verificar tamaños
# ============================================================
if [ -f all_found.txt ] && [ -s all_found.txt ]; then
    echo "[7] Verificando tamaños de archivos..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    > files_with_size.txt

    while IFS= read -r url; do
        size=$(curl -sI "$url" --max-time 3 | grep -i "content-length" | awk '{print $2}' | tr -d '\r')

        if [ -n "$size" ]; then
            size_mb=$(echo "scale=2; $size/1024/1024" | bc)
            printf "%-80s %10s MB\n" "$url" "$size_mb" >> files_with_size.txt
            printf "  %-60s %10s MB\n" "$(basename $url)" "$size_mb"
        fi
    done < all_found.txt

    echo ""
fi

# ============================================================
# Resultados finales
# ============================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    RESULTADOS FINALES                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "📊 Resumen:"
echo "  Archivos encontrados: $(wc -l < found_files.txt 2>/dev/null || echo 0)"
echo "  Directorios encontrados: $(wc -l < found_dirs.txt 2>/dev/null || echo 0)"
echo "  Archivos por fecha: $(wc -l < found_by_date.txt 2>/dev/null || echo 0)"
echo "  Total único: $total"
echo ""

if [ $total -gt 0 ]; then
    echo "📄 Archivos/Directorios encontrados:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat all_found.txt
    echo ""

    if [ -f files_with_size.txt ]; then
        echo "📏 Tamaños:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat files_with_size.txt
        echo ""
    fi
fi

echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✅ Fuzzing completado"
echo "📁 Resultados en: $(pwd)"
echo ""

# Listar archivos generados
echo "📄 Archivos generados:"
ls -lh *.txt *.json 2>/dev/null

echo ""
