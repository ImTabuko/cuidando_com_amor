# 🔧 Solução: Erro no Netlify Build

## ❌ Erro que você recebeu:
```
Failed during stage 'building site': Build script returned non-zero exit code: 2
```

## 🎯 Causa do Problema

O Netlify **não tem Flutter instalado** por padrão. Quando você tenta fazer deploy direto do GitHub, o Netlify tenta executar `flutter build web --release`, mas o comando `flutter` não existe no servidor.

## ✅ Solução: Build Local + Netlify Drop

### Método 1: Netlify Drop (Mais Fácil)

1. **Faça o build localmente:**
   ```bash
   cd cuidando_com_amor
   flutter pub get
   flutter build web --release
   ```

2. **Acesse Netlify Drop:**
   - Vá para: https://app.netlify.com/drop
   - **Arraste a pasta inteira** `build/web` para a área de drop
   - Aguarde alguns segundos
   - **Pronto!** Seu site estará online! 🎉

3. **Para atualizar:**
   - Faça build novamente localmente
   - Arraste a pasta `build/web` novamente no Netlify Drop

### Método 2: GitHub Pages (Automático)

1. **Use o GitHub Actions** que já está configurado:
   - O arquivo `.github/workflows/deploy-web.yml` já está pronto
   - Faça commit e push para a branch `main` ou `master`
   - O GitHub Actions fará o build automaticamente
   - Ative GitHub Pages em: Settings → Pages → Source: GitHub Actions

2. **Ou manualmente:**
   ```bash
   # Build local
   cd cuidando_com_amor
   flutter build web --release
   
   # Criar branch gh-pages
   git checkout -b gh-pages
   
   # Copiar arquivos
   cp -r build/web/* .
   
   # Commit e push
   git add .
   git commit -m "Deploy web"
   git push origin gh-pages
   ```

### Método 3: Netlify com Build Local (Avançado)

Se você realmente quer usar o Netlify com GitHub:

1. **Faça build local e commit a pasta build:**
   ```bash
   cd cuidando_com_amor
   flutter build web --release
   git add build/web
   git commit -m "Add web build"
   git push
   ```

2. **Configure Netlify:**
   - Base directory: `cuidando_com_amor`
   - Build command: (deixe vazio)
   - Publish directory: `cuidando_com_amor/build/web`

3. **⚠️ Desvantagem:** Você precisa fazer commit da pasta build toda vez que atualizar.

## 🚀 Recomendação

**Use o Netlify Drop** - é o método mais simples e rápido:
- ✅ Não precisa configurar nada
- ✅ Funciona imediatamente
- ✅ Gratuito
- ✅ HTTPS automático
- ✅ URL personalizada

## 📝 Scripts de Ajuda

Use os scripts que criei:
- **Windows:** `build-and-deploy.bat`
- **Linux/Mac:** `build-and-deploy.sh`

Eles fazem tudo automaticamente!

