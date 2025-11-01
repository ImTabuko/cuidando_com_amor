import 'dart:convert';
import 'package:http/http.dart' as http;

class CEPService {
  static const String baseUrl = 'https://viacep.com.br/ws';

  static Future<Map<String, String?>> getAddressByCEP(String cep) async {
    try {
      // Remove caracteres especiais do CEP
      final cleanedCEP = cep.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleanedCEP.length != 8) {
        return {};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$cleanedCEP/json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // ViaCEP retorna erro se CEP não existir
        if (data.containsKey('erro')) {
          return {};
        }

        return {
          'street': data['logradouro'],
          'neighborhood': data['bairro'],
          'city': data['localidade'],
          'state': data['uf'],
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}







