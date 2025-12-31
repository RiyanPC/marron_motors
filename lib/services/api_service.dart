import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? params,
  }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: params);
      print('GET Request: $uri');
      final response = await http.get(uri);
      print('GET Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error en la petición: ${response.statusCode}');
      }
    } catch (e) {
      print('GET Exception: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> post(String url, dynamic body) async {
    try {
      print('POST Request: $url');
      print('POST Body: ${json.encode(body)}');
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      print('POST Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Error en la petición: ${response.statusCode}');
      }
    } catch (e) {
      print('POST Exception: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}
