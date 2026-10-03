import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // เปลี่ยน URL เป็นของ backend1 ของคุณ
  static const String baseUrl = 'http://127.0.0.1:8000/api'; 

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // 'Authorization': 'Bearer YOUR_TOKEN', // เพิ่ม Token ได้ที่นี่
      };

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: _headers);
    return _processResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'), headers: _headers);
    return _processResponse(response);
  }

  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }
}