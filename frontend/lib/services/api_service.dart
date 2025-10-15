import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator. Use 'localhost' for iOS Simulator.
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  Future<String> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Successfully return the token
        return responseBody['token'];
      } else {
        // Handle logical errors from the server (e.g., wrong password)
        throw Exception(responseBody['message'] ?? 'An unknown error occurred');
      }
    } catch (e) {
      // Handle network or other exceptions
      throw Exception('Failed to connect to the server. Please check your connection.');
    }
  }

  // TODO: Add other API methods here (e.g., register, getTournaments, etc.)
}