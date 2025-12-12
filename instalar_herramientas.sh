#!/bin/bash
#
# Script para instalar TODAS las herramientas de endpoint discovery
#

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     Instalador de Herramientas de Endpoint Discovery         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Verificar si Go está instalado
if ! command -v go &> /dev/null; then
    echo "❌ Go no está instalado"
    echo "Instalar con: sudo apt install golang-go -y"
    exit 1
fi

echo "✓ Go está instalado: $(go version)"
echo ""

# Configurar GOPATH si no existe
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

echo "Instalando herramientas..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================
# 1. Katana
# ============================================================
echo "[1] Instalando Katana..."
go install github.com/projectdiscovery/katana/cmd/katana@latest
if [ $? -eq 0 ]; then
    echo "  ✓ Katana instalado"
else
    echo "  ✗ Error instalando Katana"
fi
echo ""

# ============================================================
# 2. waybackurls
# ============================================================
echo "[2] Instalando waybackurls..."
go install github.com/tomnomnom/waybackurls@latest
if [ $? -eq 0 ]; then
    echo "  ✓ waybackurls instalado"
else
    echo "  ✗ Error instalando waybackurls"
fi
echo ""

# ============================================================
# 3. gau
# ============================================================
echo "[3] Instalando gau..."
go install github.com/lc/gau/v2/cmd/gau@latest
if [ $? -eq 0 ]; then
    echo "  ✓ gau instalado"
else
    echo "  ✗ Error instalando gau"
fi
echo ""

# ============================================================
# 4. gospider
# ============================================================
echo "[4] Instalando gospider..."
go install github.com/jaeles-project/gospider@latest
if [ $? -eq 0 ]; then
    echo "  ✓ gospider instalado"
else
    echo "  ✗ Error instalando gospider"
fi
echo ""

# ============================================================
# 5. hakrawler
# ============================================================
echo "[5] Instalando hakrawler..."
go install github.com/hakluke/hakrawler@latest
if [ $? -eq 0 ]; then
    echo "  ✓ hakrawler instalado"
else
    echo "  ✗ Error instalando hakrawler"
fi
echo ""

# ============================================================
# 6. httpx (verificar URLs activas)
# ============================================================
echo "[6] Instalando httpx..."
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
if [ $? -eq 0 ]; then
    echo "  ✓ httpx instalado"
else
    echo "  ✗ Error instalando httpx"
fi
echo ""

# ============================================================
# 7. subfinder
# ============================================================
echo "[7] Instalando subfinder..."
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
if [ $? -eq 0 ]; then
    echo "  ✓ subfinder instalado"
else
    echo "  ✗ Error instalando subfinder"
fi
echo ""

# ============================================================
# 8. nuclei
# ============================================================
echo "[8] Instalando nuclei..."
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
if [ $? -eq 0 ]; then
    echo "  ✓ nuclei instalado"
else
    echo "  ✗ Error instalando nuclei"
fi
echo ""

# ============================================================
# Verificar instalación
# ============================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    VERIFICACIÓN                                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

tools=("katana" "waybackurls" "gau" "gospider" "hakrawler" "httpx" "subfinder" "nuclei")

for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        version=$($tool -version 2>/dev/null || $tool --version 2>/dev/null || echo "instalado")
        echo "  ✓ $tool - $version"
    else
        echo "  ✗ $tool - no encontrado"
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

# Configurar PATH permanentemente
if ! grep -q "export PATH=\$PATH:\$HOME/go/bin" ~/.zshrc; then
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc
    echo "✓ PATH configurado en ~/.zshrc"
fi

if ! grep -q "export PATH=\$PATH:\$HOME/go/bin" ~/.bashrc; then
    echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    echo "✓ PATH configurado en ~/.bashrc"
fi

echo ""
echo "✅ Instalación completada"
echo ""
echo "Ejecuta para aplicar PATH:"
echo "  source ~/.zshrc   (o ~/.bashrc si usas bash)"
echo ""
