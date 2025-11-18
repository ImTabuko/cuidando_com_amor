
class SignLanguageService {
  static final SignLanguageService _instance = SignLanguageService._internal();
  factory SignLanguageService() => _instance;
  SignLanguageService._internal();

  // API do VLibras - usando widget VLibras via iframe/embed
  // O VLibras oferece um widget JavaScript que pode ser integrado
  // Para web, vamos usar o widget VLibras diretamente
  // URL do widget VLibras: https://www.vlibras.gov.br/
  static const String _vlibrasWidgetUrl = 'https://www.vlibras.gov.br/app/';
  
  // Alternativa: usar widget VLibras diretamente (mais simples)
  // O VLibras também oferece um widget JavaScript que pode ser integrado via WebView
  
  bool _isEnabled = false;
  String _region = 'PB'; // Paraíba como padrão (pode ser alterado)

  // Getters
  bool get isEnabled => _isEnabled;
  String get region => _region;

  // Ativar/desativar tradução para Libras
  void enable() {
    _isEnabled = true;
  }

  void disable() {
    _isEnabled = false;
  }

  void toggle() {
    _isEnabled = !_isEnabled;
  }

  // Definir região (PB, RJ, SP, etc.)
  void setRegion(String region) {
    _region = region;
  }

  // Método combinado: traduzir texto e obter vídeo
  // Usando o widget VLibras que funciona via iframe
  Future<String?> translateAndGetVideo(String text) async {
    if (!_isEnabled || text.isEmpty) return null;
    
    try {
      // O VLibras funciona via widget JavaScript embutido
      // Para Flutter Web, vamos retornar uma URL que pode ser usada em um iframe
      // O widget VLibras processa o texto automaticamente
      final encodedText = Uri.encodeComponent(text);
      // Retornar URL do widget VLibras com o texto
      return '$_vlibrasWidgetUrl?text=$encodedText';
    } catch (e) {
      print('Erro ao traduzir e obter vídeo: $e');
      return null;
    }
  }

}

