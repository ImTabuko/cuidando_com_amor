# 🌐 Guia de Deploy Web - Cuidando com Amor

Este guia mostra como hospedar o aplicativo Flutter como um site na web.

## 📋 Pré-requisitos

1. Conta no GitHub (gratuita)
2. Conta no Vercel ou Netlify (gratuitas)
3. Flutter instalado localmente

## 🚀 Opção 1: Deploy no Vercel (Recomendado)

### Passo 1: Preparar o Projeto

1. Certifique-se de que o código está no GitHub
2. O arquivo `vercel.json` já está configurado na raiz do projeto

### Passo 2: Conectar ao Vercel

1. Acesse [vercel.com](https://vercel.com)
2. Faça login com sua conta GitHub
3. Clique em "Add New Project"
4. Selecione o repositório do projeto
5. Configure:
   - **Framework Preset**: Other
   - **Build Command**: `cd cuidando_com_amor && flutter build web --release`
   - **Output Directory**: `cuidando_com_amor/build/web`
   - **Install Command**: (deixe vazio ou `flutter pub get`)

### Passo 3: Variáveis de Ambiente (se necessário)

Se o app precisar de variáveis de ambiente, adicione em:
- Settings → Environment Variables

### Passo 4: Deploy

1. Clique em "Deploy"
2. Aguarde o build (pode demorar alguns minutos na primeira vez)
3. Seu site estará disponível em: `https://seu-projeto.vercel.app`

## 🌐 Opção 2: Deploy no Netlify

### Passo 1: Preparar o Projeto

1. Certifique-se de que o código está no GitHub
2. O arquivo `netlify.toml` já está configurado na raiz do projeto

### Passo 2: Conectar ao Netlify

1. Acesse [netlify.com](https://netlify.com)
2. Faça login com sua conta GitHub
3. Clique em "Add new site" → "Import an existing project"
4. Selecione o repositório do projeto
5. Configure:
   - **Base directory**: `cuidando_com_amor`
   - **Build command**: `flutter build web --release`
   - **Publish directory**: `build/web`

### Passo 3: Deploy

1. Clique em "Deploy site"
2. Aguarde o build
3. Seu site estará disponível em: `https://seu-projeto.netlify.app`

## 🔧 Opção 3: Deploy Manual (GitHub Pages)

### Passo 1: Build Local

```bash
cd cuidando_com_amor
flutter build web --release
```

### Passo 2: Configurar GitHub Pages

1. No GitHub, vá em Settings → Pages
2. Source: Deploy from a branch
3. Branch: `gh-pages` (crie esta branch)
4. Folder: `/build/web`

### Passo 3: Fazer Upload

```bash
# Criar branch gh-pages
git checkout -b gh-pages

# Copiar arquivos build
cp -r build/web/* .

# Commit e push
git add .
git commit -m "Deploy web"
git push origin gh-pages
```

## ⚙️ Configurações Importantes

### Base URL

O app já está configurado para funcionar em qualquer subdiretório. O `index.html` usa `$FLUTTER_BASE_HREF` que é configurado automaticamente.

### API Backend

Certifique-se de que a URL da API no `data_service.dart` está correta:

```dart
static const String _baseUrl = 'https://cuidando-com-amor.vercel.app/api';
```

Ou configure uma variável de ambiente.

## 🐛 Solução de Problemas

### Erro: "Flutter command not found"

No Vercel/Netlify, adicione no build command:
```bash
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.x.x-stable.tar.xz | tar xJ
export PATH="$PATH:`pwd`/flutter/bin"
```

Ou use uma imagem Docker com Flutter pré-instalado.

### Erro: "Build failed"

1. Verifique se todas as dependências estão no `pubspec.yaml`
2. Certifique-se de que o Flutter está na versão estável
3. Verifique os logs de build no painel do Vercel/Netlify

### App não carrega

1. Verifique se o `index.html` está correto
2. Verifique o console do navegador (F12)
3. Certifique-se de que todas as rotas redirecionam para `index.html`

## 📱 PWA (Progressive Web App)

O app já está configurado como PWA:
- ✅ Manifest.json configurado
- ✅ Ícones para diferentes tamanhos
- ✅ Suporte a instalação no dispositivo
- ✅ Funciona offline (após primeiro carregamento)

## 🔒 Segurança

Os arquivos de configuração já incluem:
- Headers de segurança
- Cache otimizado para assets
- Proteção XSS

## 📊 Monitoramento

Após o deploy, você pode:
- Ver estatísticas de acesso no painel do Vercel/Netlify
- Configurar domínio personalizado
- Configurar SSL (automático)

## 🎉 Pronto!

Seu app Flutter agora está disponível como um site web! 🚀







