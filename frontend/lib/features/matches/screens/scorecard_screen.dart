// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/material.dart' show MaterialStateProperty;
// import 'package:path_provider/path_provider.dart';
// import 'package:screenshot/screenshot.dart';
// import 'package:share_plus/share_plus.dart';

// class ScorecardScreen extends StatefulWidget {
//   final String teamA;
//   final String teamB;

//   const ScorecardScreen({super.key, required this.teamA, required this.teamB});

//   @override
//   State<ScorecardScreen> createState() => _ScorecardScreenState();
// }

// class _ScorecardScreenState extends State<ScorecardScreen> {
//   final ScreenshotController screenshotController = ScreenshotController();

//   /// 🔹 Capture screenshot and save/share as PNG
//   // Future<void> _downloadScorecard() async {
//   //   try {
//   //     final Uint8List? imageBytes = await screenshotController.capture(
//   //       delay: const Duration(milliseconds: 200),
//   //     );

//   //     if (imageBytes != null) {
//   //       final directory = await getApplicationDocumentsDirectory();
//   //       final filePath = '${directory.path}/scorecard.png';
//   //       final file = File(filePath);
//   //       await file.writeAsBytes(imageBytes);

//   //       // ✅ Share after saving
//   //       await Share.shareXFiles([XFile(filePath)], text: '📊 Match Scorecard');

//   //       if (!mounted) return;
//   //       ScaffoldMessenger.of(
//   //         context,
//   //       ).showSnackBar(SnackBar(content: Text('✅ Scorecard saved at: $filePath')));
//   //     }
//   //   } catch (e) {
//   //     debugPrint("❌ Error saving scorecard: $e");
//   //     if (!mounted) return;
//   //     ScaffoldMessenger.of(
//   //       context,
//   //     ).showSnackBar(const SnackBar(content: Text('Error saving scorecard')));
//   //   }
//   // }

//   // /// 🔹 Build innings card with DataTable
//   Widget _buildInningsCard(String team, List<Map<String, String>> batting) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1A2C22),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             team,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 10),
//           DataTable(
//             headingRowColor: MaterialStateProperty.all(Colors.black54),
//             headingTextStyle: const TextStyle(
//               color: Colors.grey,
//               fontSize: 13,
//               fontWeight: FontWeight.bold,
//             ),
//             dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
//             columns: const [
//               DataColumn(label: Text("Player")),
//               DataColumn(label: Text("R")),
//               DataColumn(label: Text("B")),
//               DataColumn(label: Text("4s")),
//               DataColumn(label: Text("6s")),
//               DataColumn(label: Text("SR")),
//             ],
//             rows: batting
//                 .map(
//                   (p) => DataRow(
//                     cells: [
//                       DataCell(Text(p['name'] ?? "")),
//                       DataCell(Text(p['runs'] ?? "0")),
//                       DataCell(Text(p['balls'] ?? "0")),
//                       DataCell(Text(p['fours'] ?? "0")),
//                       DataCell(Text(p['sixes'] ?? "0")),
//                       DataCell(Text(p['sr'] ?? "0.0")),
//                     ],
//                   ),
//                 )
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // 🔹 Dummy data for demo (replace with real backend data)
//     final teamABatting = [
//       {
//         "name": "Player A1",
//         "runs": "45",
//         "balls": "30",
//         "fours": "6",
//         "sixes": "2",
//         "sr": "150",
//       },
//       {
//         "name": "Player A2",
//         "runs": "20",
//         "balls": "25",
//         "fours": "2",
//         "sixes": "0",
//         "sr": "80",
//       },
//     ];

//     final teamBBatting = [
//       {
//         "name": "Player B1",
//         "runs": "60",
//         "balls": "40",
//         "fours": "8",
//         "sixes": "1",
//         "sr": "150",
//       },
//       {
//         "name": "Player B2",
//         "runs": "10",
//         "balls": "15",
//         "fours": "1",
//         "sixes": "0",
//         "sr": "66",
//       },
//     ];

//     return Scaffold(
//       backgroundColor: const Color(0xFF122118),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF122118),
//         title: const Text(
//           "Scorecard",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Column(
//         children: [
//           // Expanded(
//           //   // child: Screenshot(
//           //   //   controller: screenshotController,
//           //   //   child: SingleChildScrollView(
//           //   //     padding: const EdgeInsets.all(12),
//           //   //     child: Column(
//           //   //       children: [
//           //   //         _buildInningsCard(widget.teamA, teamABatting),
//           //   //         _buildInningsCard(widget.teamB, teamBBatting),
//           //   //       ],
//           //   //     ),
//           //   //   ),
//           //   // ),
//           // ),
//           Container(
//             padding: const EdgeInsets.all(12),
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: () {
//                 // _downloadScorecard();
//               },
//               icon: const Icon(Icons.download),
//               label: const Text("Download Scorecard (PNG)"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF38e07b),
//                 foregroundColor: Colors.black,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
