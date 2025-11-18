#!/bin/bash

echo "========================================"
echo "  Build e Deploy - Cuidando com Amor"
echo "========================================"
echo ""

echo "[1/3] Limpando builds anteriores..."
rm -rf build
echo "OK!"
echo ""

echo "[2/3] Obtendo dependências..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERRO: Falha ao obter dependências!"
    exit 1
fi
echo "OK!"
echo ""

echo "[3/3] Construindo para web..."
flutter build web --release
if [ $? -ne 0 ]; then
    echo "ERRO: Falha ao construir!"
    exit 1
fi
echo ""
echo "========================================"
echo "  Build concluído com sucesso!"
echo "========================================"
echo ""
echo "Próximos passos:"
echo "1. Acesse: https://app.netlify.com/drop"
echo "2. Arraste a pasta: build/web"
echo "3. Pronto! Seu site estará online!"
echo ""


