# 🚀 Deploy Rápido - Cuidando com Amor Web

## ⚠️ IMPORTANTE: Build Local Necessário

O Netlify/Vercel **não tem Flutter instalado**, então você precisa fazer o build localmente primeiro.

## ✅ Opção Mais Rápida: Netlify Drop

### Passo 1: Build Local

**Windows:**
```bash
cd cuidando_com_amor
build-and-deploy.bat
```

**Linux/Mac:**
```bash
cd cuidando_com_amor
chmod +x build-and-deploy.sh
./build-and-deploy.sh
```

**Ou manualmente:**
```bash
cd cuidando_com_amor
flutter pub get
flutter build web --release
```

### Passo 2: Deploy no Netlify Drop

1. **Acesse:** [app.netlify.com/drop](https://app.netlify.com/drop)
2. **Arraste a pasta:** `cuidando_com_amor/build/web` (arraste a pasta inteira)
3. **Pronto!** Seu site estará online em segundos! 🎉

**Vantagens:**
- ✅ Gratuito
- ✅ Sem configuração
- ✅ Funciona imediatamente
- ✅ HTTPS automático

## Opção 2: Vercel (Requer Build Local)

O Vercel também não tem Flutter. Você precisa fazer build local e fazer upload:

1. **Build local** (veja Passo 1 acima)
2. **Instale Vercel CLI:**
   ```bash
   npm install -g vercel
   ```
3. **Deploy:**
   ```bash
   cd cuidando_com_amor/build/web
   vercel --prod
   ```
4. **Pronto!** Seu site estará em `https://seu-projeto.vercel.app`

**Ou use GitHub Actions** (veja `.github/workflows/deploy-web.yml`)

## Opção 3: GitHub Pages (Gratuito)

1. **Build:**
```bash
cd cuidando_com_amor
flutter build web --release
```

2. **No GitHub:**
   - Vá em Settings → Pages
   - Source: Deploy from a branch
   - Branch: `gh-pages`
   - Folder: `/build/web`

3. **Criar branch e fazer upload:**
```bash
git checkout -b gh-pages
cd cuidando_com_amor
cp -r build/web/* ../.
cd ..
git add .
git commit -m "Deploy web"
git push origin gh-pages
```

## ⚠️ Importante

- Certifique-se de que a URL da API está correta no `data_service.dart`
- O app funcionará como PWA (pode ser instalado no celular)
- Funciona em qualquer navegador moderno

## 🔗 Links Úteis

- [Netlify Drop](https://app.netlify.com/drop) - Mais rápido
- [Vercel](https://vercel.com) - Melhor para projetos GitHub
- [GitHub Pages](https://pages.github.com) - Gratuito com GitHub

