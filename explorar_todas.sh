#!/bin/bash
#
# Script para explorar TODAS las carpetas de /assets/
#

clear
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Exploración Completa de TODAS las carpetas de /assets/    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

cd ~/viva-pentest
mkdir -p exploracion_completa
cd exploracion_completa

# Descargar .DS_Store principal
curl -s https://app.viva.com.bo/assets/.DS_Store -o assets.DS_Store

# Obtener lista de carpetas
carpetas=$(python3 << 'EOF'
from ds_store import DSStore
with DSStore.open("assets.DS_Store", "r+") as d:
    for e in sorted(set(e.filename for e in d)):
        print(e)
EOF
)

echo "Carpetas encontradas en /assets/:"
echo "$carpetas" | sed 's/^/  📁 /'
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Explorar cada carpeta
total_archivos=0

for carpeta in $carpetas; do
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  📂 Explorando: /assets/$carpeta/"
    echo "╚═══════════════════════════════════════════════════════════════╝"

    mkdir -p "$carpeta"
    cd "$carpeta"

    # 1. Intentar .DS_Store
    echo ""
    echo "[1] Buscando .DS_Store..."
    curl -s "https://app.viva.com.bo/assets/$carpeta/.DS_Store" -o ds_store.bin

    if file ds_store.bin | grep -q "Apple Desktop"; then
        echo "  ✓ .DS_Store encontrado!"

        python3 << EOF
from ds_store import DSStore
try:
    with DSStore.open("ds_store.bin", "r+") as d:
        archivos = sorted(set(e.filename for e in d))
        print(f"\n  Archivos encontrados: {len(archivos)}")
        print("")
        for f in archivos[:20]:
            print(f"    📄 {f}")
        if len(archivos) > 20:
            print(f"    ... y {len(archivos) - 20} más")
except Exception as e:
    print(f"  Error parseando: {e}")
EOF
    else
        echo "  ✗ No hay .DS_Store"
    fi

    # 2. Directory listing
    echo ""
    echo "[2] Probando directory listing..."
    status=$(curl -s -o /dev/null -w "%{http_code}" "https://app.viva.com.bo/assets/$carpeta/")

    if [ "$status" = "200" ]; then
        echo "  ✓ Accesible [$status]"
        curl -s "https://app.viva.com.bo/assets/$carpeta/" > directory_listing.html
    elif [ "$status" = "403" ]; then
        echo "  ✗ Bloqueado [$status]"
    else
        echo "  ? [$status]"
    fi

    # 3. Fuzzing de archivos comunes según el tipo de carpeta
    echo ""
    echo "[3] Fuzzing de archivos comunes..."

    found=0

    case "$carpeta" in
        "audio")
            nombres=(notification alert success error click beep sound)
            extensiones=(mp3 wav ogg)
            ;;
        "data")
            nombres=(data config version info settings list)
            extensiones=(json xml txt)
            ;;
        "bancos")
            nombres=(bcp bisa bnb mercantil bancos banks config)
            extensiones=(json xml txt)
            ;;
        "js")
            nombres=(app main config script bundle index)
            extensiones=(js json)
            ;;
        "css")
            nombres=(style main app theme)
            extensiones=(css)
            ;;
        "html")
            nombres=(index login dashboard admin)
            extensiones=(html)
            ;;
        "pdf")
            nombres=(manual guide docs terms)
            extensiones=(pdf)
            ;;
        "img")
            nombres=(logo icon banner background)
            extensiones=(png jpg svg gif)
            ;;
        *)
            nombres=(index data config)
            extensiones=(json txt)
            ;;
    esac

    for nombre in "${nombres[@]}"; do
        for ext in "${extensiones[@]}"; do
            url="https://app.viva.com.bo/assets/$carpeta/${nombre}.${ext}"
            s=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 3)

            if [ "$s" = "200" ]; then
                size=$(curl -s "$url" --max-time 5 | wc -c)
                echo "  ✓ ${nombre}.${ext} ($size bytes)"
                curl -s "$url" -o "${nombre}.${ext}"
                ((found++))
                ((total_archivos++))
            fi
        done
    done

    if [ $found -eq 0 ]; then
        echo "  ✗ No se encontraron archivos"
    else
        echo "  ✓ Encontrados: $found archivos"
    fi

    cd ..
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
done

# Resumen final
echo ""
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    RESUMEN FINAL                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total de carpetas exploradas: $(echo "$carpetas" | wc -l)"
echo "Total de archivos encontrados: $total_archivos"
echo ""
echo "Resultados guardados en: $(pwd)"
echo ""

# Mostrar archivos encontrados por carpeta
echo "Archivos por carpeta:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for carpeta in $carpetas; do
    if [ -d "$carpeta" ]; then
        count=$(find "$carpeta" -type f ! -name "ds_store.bin" ! -name "*.html" | wc -l)
        if [ $count -gt 0 ]; then
            echo ""
            echo "📁 $carpeta/ ($count archivos)"
            find "$carpeta" -type f ! -name "ds_store.bin" ! -name "*.html" -exec ls -lh {} \; | awk '{print "   " $9 " - " $5}'
        fi
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""
