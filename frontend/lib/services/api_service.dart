import '../core/api_client.dart';

class ApiService {
  Future<String> login(String phoneNumber, String password) async {
    final resp =
        await ApiClient.instance.postJson(
              '/api/auth/login',
              body: {'phone_number': phoneNumber, 'password': password},
            )
            as Map<String, dynamic>;
    return resp['token']?.toString() ?? '';
  }
}
