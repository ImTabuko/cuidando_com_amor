@echo off
echo ========================================
echo   Build e Deploy - Cuidando com Amor
echo ========================================
echo.

echo [1/3] Limpando builds anteriores...
if exist build rmdir /s /q build
echo OK!
echo.

echo [2/3] Obtendo dependencias...
flutter pub get
if errorlevel 1 (
    echo ERRO: Falha ao obter dependencias!
    pause
    exit /b 1
)
echo OK!
echo.

echo [3/3] Construindo para web...
flutter build web --release
if errorlevel 1 (
    echo ERRO: Falha ao construir!
    pause
    exit /b 1
)
echo.
echo ========================================
echo   Build concluido com sucesso!
echo ========================================
echo.
echo Proximos passos:
echo 1. Acesse: https://app.netlify.com/drop
echo 2. Arraste a pasta: build\web
echo 3. Pronto! Seu site estara online!
echo.
echo Ou use GitHub Pages:
echo 1. Vá em Settings ^> Pages no GitHub
echo 2. Configure para usar a branch gh-pages
echo 3. Execute: git checkout -b gh-pages
echo 4. Copie build\web para a raiz e faca commit
echo.
pause



