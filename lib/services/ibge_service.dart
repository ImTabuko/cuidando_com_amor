import 'dart:convert';
import 'package:http/http.dart' as http;

class IBGEService {
  static const String baseUrl = 'https://servicodados.ibge.gov.br/api/v1/localidades';

  // Obter lista de estados
  static Future<List<Map<String, String>>> getStates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estados?orderBy=nome'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((state) {
          return {
            'sigla': state['sigla'].toString(),
            'nome': state['nome'].toString(),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Obter cidades de um estado
  static Future<List<String>> getCitiesByState(String stateCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estados/$stateCode/municipios?orderBy=nome'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((city) => city['nome'] as String).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

