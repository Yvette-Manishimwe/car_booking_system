// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import '../Others/booking_screen.dart';
// import '../Others/user_profile_screen.dart';
// import '../Others/user_trips_screen.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this); // 3 tabs: Trips, Booking, Profile
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Car Booking App'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: [
//             Tab(text: "Trips"),
//             Tab(text: "Booking"),
//             Tab(text: "Profile"),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           UserTripsScreen(),
//           BookingScreen(),
//           UserProfileScreen(),
//         ],
//       ),
//     );
//   }
// }