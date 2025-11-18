# 🔗 Atualizar URL do Backend

Se você deployou o backend em um servidor diferente, precisa atualizar a URL no app Flutter.

## 📍 Onde Atualizar

Arquivo: `lib/services/data_service.dart`

Linha 27:
```dart
static const String _baseUrl = 'https://cuidando-com-amor.vercel.app/api';
```

## 🔧 Como Atualizar

1. Abra o arquivo `lib/services/data_service.dart`
2. Encontre a linha 27
3. Substitua pela URL do seu backend:

```dart
static const String _baseUrl = 'https://SEU-BACKEND.vercel.app/api';
```

Ou se estiver usando Render:

```dart
static const String _baseUrl = 'https://SEU-BACKEND.onrender.com/api';
```

## ✅ Verificar

Após atualizar, faça um novo build:

```bash
flutter build web --release
```

E teste se o app consegue se conectar ao backend!


