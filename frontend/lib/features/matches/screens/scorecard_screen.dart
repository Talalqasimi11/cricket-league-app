import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/api_client.dart';

class ScorecardScreen extends StatefulWidget {
  final String matchId;
  const ScorecardScreen({super.key, required this.matchId});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  bool _loading = true;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse('${ApiClient.baseUrl}/api/viewer/scorecard/${widget.matchId}'));
      if (resp.statusCode == 200) {
        data = jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF122118),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        title: const Text(
          'Scorecard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (data == null) const Text('No data', style: TextStyle(color: Colors.white)),
                if (data != null) ...[
                  _section('Innings', data!['innings'] as List<dynamic>?),
                  const SizedBox(height: 12),
                  _section('Batting', data!['batting'] as List<dynamic>?),
                  const SizedBox(height: 12),
                  _section('Bowling', data!['bowling'] as List<dynamic>?),
                ],
              ],
            ),
    );
  }

  Widget _section(String title, List<dynamic>? rows) {
    rows ??= const [];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...rows.map((r) => Text(r.toString(), style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}
