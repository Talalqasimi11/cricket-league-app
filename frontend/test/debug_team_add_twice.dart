import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  const baseUrl = 'http://localhost:5000';
  String? token;

  // Setup: Register and Login to get a token
  setUpAll(() async {
    final email = 'debug_${DateTime.now().millisecondsSinceEpoch}@test.com';
    const password = 'password123';

    // Register
    await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': 'DebugUser_${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'password': password,
      }),
    );

    // Login
    final loginResp = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (loginResp.statusCode == 200) {
      final body = jsonDecode(loginResp.body);
      token = body['token'];
      print('🔑 Logged in. Token obtained.');
    } else {
      throw Exception('Failed to login for test: ${loginResp.body}');
    }
  });

  test('Debug Team Add Twice', () async {
    print('🚀 Starting Debug Script for Adding Teams Twice...');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // 1. Create Tournament
    final tName = 'Debug T ${DateTime.now().millisecondsSinceEpoch}';
    final tResp = await http.post(
      Uri.parse('$baseUrl/api/tournaments'),
      headers: headers,
      body: jsonEncode({
        'tournament_name': tName,
        'location': 'Lab',
        'overs': 10,
        'type': 'knockout',
      }),
    );

    if (tResp.statusCode != 201 && tResp.statusCode != 200) {
      fail('Failed to create tournament: ${tResp.body}');
    }
    final tId = RegExp(
      r'"tournament_id":\s*"?(\d+)"?',
    ).firstMatch(tResp.body)?.group(1);
    if (tId == null) fail('No Tournament ID');
    print('✅ Tournament Created: $tId');

    // 2. Create Team A and Team B
    final teamAResp = await http.post(
      Uri.parse('$baseUrl/api/teams'),
      headers: headers,
      body: jsonEncode({
        'team_name': 'Team A $tName',
        'team_location': 'Loc A',
      }),
    );
    final teamBResp = await http.post(
      Uri.parse('$baseUrl/api/teams'),
      headers: headers,
      body: jsonEncode({
        'team_name': 'Team B $tName',
        'team_location': 'Loc B',
      }),
    );

    final idRegExp = RegExp(r'"team_id":\s*"?(\d+)"?');
    final idA = idRegExp.firstMatch(teamAResp.body)?.group(1);
    final idB = idRegExp.firstMatch(teamBResp.body)?.group(1);

    if (idA == null || idB == null) fail('Failed to get Team IDs');
    print('✅ Teams Created: A($idA), B($idB)');

    // 3. Add Team A
    print('👉 Adding Team A...');
    final addAResp = await http.post(
      Uri.parse('$baseUrl/api/tournaments/$tId/teams'),
      headers: headers,
      body: jsonEncode({
        'team_ids': [idA],
      }),
    );
    print('   Status: ${addAResp.statusCode}');
    if (addAResp.statusCode != 200 && addAResp.statusCode != 201) {
      fail('Failed to add Team A: ${addAResp.body}');
    }

    // 4. Verify Team A is there
    var teamsResp = await http.get(
      Uri.parse('$baseUrl/api/tournament-teams/$tId'),
      headers: headers,
    );
    if (!teamsResp.body.contains('"team_id":$idA') &&
        !teamsResp.body.contains('"team_id":"$idA"')) {
      fail('Team A not found after adding');
    }
    print('✅ Team A verified');

    // 5. Add Team B
    print('👉 Adding Team B...');
    final addBResp = await http.post(
      Uri.parse('$baseUrl/api/tournaments/$tId/teams'),
      headers: headers,
      body: jsonEncode({
        'team_ids': [idB],
      }),
    );
    print('   Status: ${addBResp.statusCode}');
    print('   Body: ${addBResp.body}');
    if (addBResp.statusCode != 200 && addBResp.statusCode != 201) {
      fail('Failed to add Team B: ${addBResp.body}');
    }

    // 6. Verify Team B is there
    teamsResp = await http.get(
      Uri.parse('$baseUrl/api/tournament-teams/$tId'),
      headers: headers,
    );
    print('   Final Teams Body: ${teamsResp.body}');

    final hasA =
        teamsResp.body.contains('"team_id":$idA') ||
        teamsResp.body.contains('"team_id":"$idA"');
    final hasB =
        teamsResp.body.contains('"team_id":$idB') ||
        teamsResp.body.contains('"team_id":"$idB"');

    if (!hasA) print('❌ Team A disappeared!');
    if (!hasB) print('❌ Team B missing!');

    if (hasA && hasB) {
      print('✅ SUCCESS: Both teams present.');
    } else {
      fail('Failed to verify both teams.');
    }
  });
}
