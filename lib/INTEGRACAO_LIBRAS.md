# 📚 Integração de Língua de Sinais (Libras) - VLibras

## ✅ O que foi implementado

1. **Serviço de Língua de Sinais** (`sign_language_service.dart`)
   - Integração com a API do VLibras
   - Tradução de texto para glosa (representação textual dos sinais)
   - Geração de vídeos de sinais a partir da glosa
   - Suporte a regionalismos (PB, RJ, SP, etc.)

2. **Widget de Intérprete** (`sign_language_interpreter.dart`)
   - Widget que exibe vídeos de sinais para textos
   - Carregamento automático quando a opção está ativada
   - Modal para visualização em tela cheia
   - Tratamento de erros

3. **Configurações de Acessibilidade**
   - Opção para ativar/desativar tradução para Libras
   - Integrado nas configurações de acessibilidade

## 🔧 Como usar

### Ativar a funcionalidade:
1. Vá em **Configurações de Acessibilidade** (ícone no AppBar)
2. Ative o switch **"Língua de Sinais (Libras)"**
3. Os textos do app serão traduzidos automaticamente

### Usar o widget em telas:
```dart
import '../widgets/sign_language_interpreter.dart';

SignLanguageInterpreter(
  text: 'Texto a ser traduzido para Libras',
  width: 200,
  height: 150,
)
```

## ⚠️ IMPORTANTE - Configuração da API

A URL da API do VLibras pode precisar ser ajustada. Para obter a URL correta:

1. Acesse: https://www.gov.br/conecta/catalogo/apis/vlibras
2. Verifique a documentação oficial da API
3. Atualize a URL em `lib/services/sign_language_service.dart`:
   ```dart
   static const String _baseUrl = 'URL_DA_API_AQUI';
   ```

## 📋 Endpoints esperados

A implementação atual espera os seguintes endpoints:

- `POST /text-to-glosa` - Traduz texto para glosa
- `POST /glosa-to-video` - Gera vídeo a partir da glosa
- `GET /dictionary` - Lista de sinais do dicionário
- `GET /health` - Verificação de disponibilidade

**Nota:** Estes endpoints podem variar na API real. Verifique a documentação oficial.

## 🔄 Alternativas

Se a API do VLibras não estiver disponível ou tiver problemas:

1. **Widget VLibras JavaScript**: Integrar via WebView
2. **Hand Talk API**: Outra opção de API de tradução
3. **Vídeos pré-gravados**: Usar vídeos estáticos para textos comuns

## 📝 Próximos passos

1. Testar a integração com a API real do VLibras
2. Adicionar cache de vídeos traduzidos
3. Implementar tradução automática em todas as telas principais
4. Adicionar opção de escolher região (PB, RJ, SP, etc.)


