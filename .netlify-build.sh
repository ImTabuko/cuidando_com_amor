#!/bin/bash
set -e

echo "🚀 Iniciando build do Flutter no Netlify..."

# Instalar Flutter
echo "📦 Instalando Flutter..."
FLUTTER_VERSION="3.24.0"
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz | tar xJ
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar instalação
flutter --version

# Navegar para o diretório do projeto
cd cuidando_com_amor

# Obter dependências
echo "📚 Obtendo dependências..."
flutter pub get

# Build para web
echo "🔨 Construindo para web..."
flutter build web --release

echo "✅ Build concluído com sucesso!"


