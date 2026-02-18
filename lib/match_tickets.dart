// import 'package:flutter/material.dart';
// import 'seat_selection.dart';
//
// class SelectTicketScreen extends StatefulWidget {
//   const SelectTicketScreen({super.key});
//
//   @override
//   State<SelectTicketScreen> createState() => _SelectTicketScreenState();
// }
//
// class _SelectTicketScreenState extends State<SelectTicketScreen> {
//   String selectedFilter = 'All';
//   String searchQuery = '';
//
//   final List<Map<String, String>> matches = [
//     {
//       'home': 'Dar City',
//       'away': 'Lakers',
//       'date': '2024-03-15',
//       'time': '19:00',
//       'venue': 'Dar City Arena',
//       'logo1': 'assets/images/dar-city-logo.png',
//       'logo2': 'assets/images/ground.jpg',
//     },
//     {
//       'home': 'Dar City',
//       'away': 'Pazzi',
//       'date': '2024-03-22',
//       'time': '20:00',
//       'venue': 'JKT Stadium',
//       'logo1': 'assets/images/dar-city-logo.png',
//       'logo2': 'assets/images/jersy.jpg',
//     },
//     {
//       'home': 'Dar City',
//       'away': 'Giants',
//       'date': '2024-04-05',
//       'time': '18:30',
//       'venue': 'Dar City Arena',
//       'logo1': 'assets/images/dar-city-logo.png',
//       'logo2': 'assets/images/pitch_seat.jpg',
//     },
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     final filteredMatches = matches.where((match) {
//       final title = '${match['home']} vs ${match['away']}'.toLowerCase();
//       return title.contains(searchQuery.toLowerCase());
//     }).toList();
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Ticket'),
//         centerTitle: true,
//         backgroundColor: Colors.black,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             /// SEARCH BAR
//             TextField(
//               onChanged: (value) {
//                 setState(() => searchQuery = value);
//               },
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText: 'Search for a match',
//                 hintStyle: const TextStyle(color: Colors.white70),
//                 filled: true,
//                 fillColor: const Color(0xFF2A2A2A),
//                 prefixIcon: const Icon(Icons.search, color: Colors.white70),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             /// FILTER BUTTONS
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: ['This Week', 'Next Month', 'All']
//                   .map((filter) => _filterButton(filter))
//                   .toList(),
//             ),
//
//             const SizedBox(height: 20),
//
//             /// MATCH LIST
//             Expanded(
//               child: ListView.builder(
//                 itemCount: filteredMatches.length,
//                 itemBuilder: (context, index) {
//                   return _matchCard(filteredMatches[index]);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// FILTER BUTTON
//   Widget _filterButton(String label) {
//     final bool isSelected = selectedFilter == label;
//
//     return ElevatedButton(
//       onPressed: () {
//         setState(() => selectedFilter = label);
//       },
//       style: ElevatedButton.styleFrom(
//         backgroundColor:
//         isSelected ? Colors.grey.shade700 : Colors.grey.shade800,
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//       child: Text(label, style: const TextStyle(color: Colors.white)),
//     );
//   }
//
//   /// MATCH CARD
//   Widget _matchCard(Map<String, String> match) {
//     return Card(
//       color: const Color(0xFF1A1A1A),
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             /// TEAM COLUMN
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _teamColumn(match['logo1']!, match['home']!),
//                 const Text(
//                   'VS',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 _teamColumn(match['logo2']!, match['away']!),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             /// DETAILS
//             Text(
//               '${match['date']} • ${match['time']}',
//               style: const TextStyle(color: Colors.white70),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               match['venue']!,
//               style: const TextStyle(color: Colors.white70),
//             ),
//
//             const SizedBox(height: 12),
//
//             /// BUY BUTTON
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Navigate to seat selection
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => SeatSelectionScreen()),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text('Buy Tickets'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// TEAM COLUMN
//   Widget _teamColumn(String logo, String name) {
//     return Column(
//       children: [
//         Image.asset(
//           logo,
//           height: 50,
//           width: 50,
//           fit: BoxFit.contain,
//         ),
//         const SizedBox(height: 6),
//         Text(
//           name,
//           style: const TextStyle(color: Colors.white),
//         ),
//       ],
//     );
//   }
// }
