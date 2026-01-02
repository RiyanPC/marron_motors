import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  Future<Map<String, dynamic>> upload(
    String url,
    File imageFile, {
    Map<String, String>? fields,
  }) async {
    try {
      print('UPLOAD Request: $url');
      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('UPLOAD Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Error en la subida: ${response.statusCode}');
      }
    } catch (e) {
      print('UPLOAD Exception: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}
