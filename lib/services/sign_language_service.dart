import 'dart:convert';
import 'package:http/http.dart' as http;

class SignLanguageService {
  static final SignLanguageService _instance = SignLanguageService._internal();
  factory SignLanguageService() => _instance;
  SignLanguageService._internal();

  // API do VLibras - endpoint público
  // NOTA: A URL exata da API pode variar. Consulte: https://www.gov.br/conecta/catalogo/apis/vlibras
  // Para uso em produção, verifique a documentação oficial da API do VLibras
  static const String _baseUrl = 'https://api.vlibras.gov.br/v1';
  
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

  // Traduzir texto para glosa (representação textual dos sinais)
  Future<String?> translateToGlosa(String text) async {
    if (text.isEmpty) return null;
    
    try {
      // API do VLibras para tradução de texto para glosa
      // Endpoint pode variar - verifique documentação oficial
      final response = await http.post(
        Uri.parse('$_baseUrl/text-to-glosa'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'text': text,
          'region': _region,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['glosa'] as String?;
      }
    } catch (e) {
      print('⚠️ Erro ao traduzir para glosa: $e');
      print('💡 Dica: Verifique se a API do VLibras está configurada corretamente');
    }
    return null;
  }

  // Obter URL do vídeo de sinais a partir da glosa
  Future<String?> getSignVideoUrl(String glosa) async {
    if (glosa.isEmpty) return null;
    
    try {
      // API do VLibras para gerar vídeo de sinais
      // Endpoint pode variar - verifique documentação oficial
      final response = await http.post(
        Uri.parse('$_baseUrl/glosa-to-video'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'glosa': glosa,
          'region': _region,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['videoUrl'] as String?;
      }
    } catch (e) {
      print('⚠️ Erro ao obter vídeo de sinais: $e');
      print('💡 Dica: A API do VLibras pode requerer autenticação ou ter endpoints diferentes');
    }
    return null;
  }

  // Método combinado: traduzir texto e obter vídeo
  Future<String?> translateAndGetVideo(String text) async {
    if (!_isEnabled || text.isEmpty) return null;
    
    try {
      final glosa = await translateToGlosa(text);
      if (glosa == null) return null;
      
      return await getSignVideoUrl(glosa);
    } catch (e) {
      print('Erro ao traduzir e obter vídeo: $e');
      return null;
    }
  }

  // Obter lista de sinais disponíveis no dicionário
  Future<List<Map<String, dynamic>>> getDictionarySigns() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dictionary'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      print('Erro ao obter dicionário: $e');
    }
    return [];
  }

  // Verificar se a API está disponível
  Future<bool> checkApiAvailability() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

