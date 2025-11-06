import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/api_client.dart';
import 'tournament_team_registration_screen.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tournamentNameController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedOvers = "10";

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Select start date')));
        return;
      }

      // Validate end date is not before start date
      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date cannot be before start date')),
        );
        return;
      }

      try {
        final resp = await ApiClient.instance.post(
          '/api/tournaments',
          body: {
            'tournament_name': _tournamentNameController.text,
            'start_date': _startDate!.toIso8601String(),
            'end_date': _endDate?.toIso8601String(),
            'location': _locationController.text,
            'overs': int.tryParse(_selectedOvers) ?? 10,
          },
        );

        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          final tournamentId = data['tournament_id']?.toString() ?? '';
          // Log response body for debugging in debug mode
          debugPrint('Tournament creation response: $data');
          if (tournamentId.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to get tournament ID. Please try again.')),
            );
            return;
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tournament created. Add teams next.'),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterTeamsScreen(
                tournamentName: _tournamentNameController.text,
                tournamentId: tournamentId,
              ),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['error']?.toString() ?? 'Failed to create tournament',
              ),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Tournament",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tournament Name
            TextFormField(
              controller: _tournamentNameController,
              decoration: const InputDecoration(
                labelText: "Tournament Name",
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? "Please enter tournament name" : null,
            ),
            const SizedBox(height: 16),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Location / Venue",
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? "Please enter location" : null,
            ),
            const SizedBox(height: 16),

            // Start & End Dates
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(context, true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Start Date",
                          border: OutlineInputBorder(),
                          hintText: "Select start date",
                        ),
                        controller: TextEditingController(
                          text: _startDate != null
                              ? "${_startDate!.day}-${_startDate!.month}-${_startDate!.year}"
                              : "",
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Select start date" : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(context, false),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "End Date",
                          border: OutlineInputBorder(),
                          hintText: "Select end date",
                        ),
                        controller: TextEditingController(
                          text: _endDate != null
                              ? "${_endDate!.day}-${_endDate!.month}-${_endDate!.year}"
                              : "",
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Select end date" : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Overs
            DropdownButtonFormField<String>(
              initialValue: _selectedOvers,
              items: ["5", "10", "20", "50"]
                  .map(
                    (e) => DropdownMenuItem(value: e, child: Text("$e Overs")),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOvers = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Number of Overs per Match",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Tournament Type (fixed knockout)
            const TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: "Tournament Type",
                hintText: "Knockout only",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _onCancel,
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _onSave,
                    child: const Text("Save Tournament"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
