// import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
// import 'payment_screen.dart';
//
//
//
// class DonateScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Donate'),
//         centerTitle: true,
//         backgroundColor: Colors.black,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: <Widget>[
//             Image.asset('assets/images/dar-city-logo.png',   width: 200,
//               height: 200,
//               fit: BoxFit.cover,
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Support Dar City Basketball',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Your contribution fuels our team\'s success and community programs. '
//                   'Every donation, big or small, makes a difference.',
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.white70,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) =>  CompletePaymentScreen()),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//               ),
//               child: const Text('Donate Now'),
//             ),
//             const SizedBox(height: 10),
//             OutlinedButton(
//               onPressed: () {
//                 // Handle become a partner action
//               },
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: Colors.white),
//                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//               ),
//               child: const Text(
//                 'Become a Partner',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }