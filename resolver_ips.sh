#!/bin/bash
#
# Script para resolver IPs de dominios_bolivia_completo.txt
#

INPUT_FILE="dominios_bolivia_completo.txt"
OUTPUT_FILE="dominios_con_ips.txt"
OUTPUT_CSV="dominios_con_ips.csv"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Resolviendo IPs de dominios_bolivia_completo.txt         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Verificar que existe el archivo de entrada
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: No se encuentra $INPUT_FILE"
    exit 1
fi

# Limpiar archivos de salida
> "$OUTPUT_FILE"
> "$OUTPUT_CSV"

# Encabezado CSV
echo "dominio,ip,estado" > "$OUTPUT_CSV"

# Contar total de dominios
total=$(wc -l < "$INPUT_FILE")
echo "📊 Total de dominios a procesar: $total"
echo ""

contador=0
resueltos=0
no_resueltos=0

echo "⏳ Procesando dominios..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Procesar cada dominio
while IFS= read -r dominio; do
    ((contador++))

    # Limpiar dominio (espacios, wildcards)
    dominio=$(echo "$dominio" | sed 's/^\*\.//g' | tr -d ' \t\r\n')

    # Saltar líneas vacías
    [ -z "$dominio" ] && continue

    # Mostrar progreso cada 50 dominios
    if [ $((contador % 50)) -eq 0 ]; then
        porcentaje=$((contador * 100 / total))
        echo "  [$contador/$total] ${porcentaje}% - Resueltos: $resueltos | No resueltos: $no_resueltos"
    fi

    # Resolver IP con dig
    ip=$(dig +short "$dominio" A @8.8.8.8 +timeout=2 +tries=1 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1)

    # Si dig falla, intentar con host
    if [ -z "$ip" ]; then
        ip=$(host "$dominio" 8.8.8.8 2>/dev/null | grep "has address" | awk '{print $4}' | head -n 1)
    fi

    # Guardar resultado
    if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        printf "%-50s → %s\n" "$dominio" "$ip" >> "$OUTPUT_FILE"
        echo "$dominio,$ip,resuelto" >> "$OUTPUT_CSV"
        ((resueltos++))
    else
        printf "%-50s → NO_RESUELTA\n" "$dominio" >> "$OUTPUT_FILE"
        echo "$dominio,,no_resuelto" >> "$OUTPUT_CSV"
        ((no_resueltos++))
    fi

done < "$INPUT_FILE"

# Resultados finales
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    RESULTADOS FINALES                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Estadísticas:"
echo "  Total procesados: $total"
echo "  ✓ IPs resueltas: $resueltos ($(awk "BEGIN {printf \"%.1f\", $resueltos*100/$total}")%)"
echo "  ✗ No resueltas: $no_resueltos ($(awk "BEGIN {printf \"%.1f\", $no_resueltos*100/$total}")%)"
echo ""
echo "📁 Archivos generados:"
echo "  📄 $OUTPUT_FILE (formato texto)"
echo "  📊 $OUTPUT_CSV (formato CSV)"
echo ""

# Mostrar primeros 20 resultados
echo "🔝 Primeros 20 dominios resueltos:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -v "NO_RESUELTA" "$OUTPUT_FILE" | head -20

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

# Top 10 IPs más comunes
echo "📈 Top 10 IPs más usadas:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -v "NO_RESUELTA" "$OUTPUT_FILE" | awk '{print $3}' | sort | uniq -c | sort -rn | head -10 | while read count ip; do
    printf "  %3d dominios → %s\n" "$count" "$ip"
done

echo ""
echo "✅ Proceso completado"
echo ""
