import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('http://localhost:5000/api/teams');
  print('Fetching teams from $url...');
  try {
    final response = await http.get(url);
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        print('Found ${data.length} teams (List)');
      } else if (data is Map && data.containsKey('data')) {
        print('Found ${data['data'].length} teams (Map with data key)');
      } else {
        print('Unknown data structure');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
