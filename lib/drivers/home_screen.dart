import 'dart:convert';
import 'package:drivers_app/drivers/trip_card.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // To track which tab is selected
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;

  // Fetch the list of trips from the server
  Future<void> fetchTrips() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.70:5000/trips'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          trips = data.cast<Map<String, dynamic>>(); // Convert to list of maps
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load trips');
      }
    } catch (e) {
      print('Error fetching trips: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTrips();
  }

  // Navigate to a different screen based on index
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Prevent redundant navigation
    setState(() {
      _selectedIndex = index;
    });

    String routeName;
    switch (index) {
      case 0:
        routeName = '/'; // Home route
        break;
      case 1:
        routeName = '/add-trip'; // Add Trip route
        break;
      case 2:
        routeName = '/earning'; // Earnings route
        break;
      case 3:
        routeName = '/drivers_notification'; // Notifications route
        break;
      case 4:
        routeName = '/account'; // Account route
        break;
      default:
        throw Exception('Invalid index');
    }

    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Trips'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Display loading indicator while fetching data
          : trips.isEmpty
              ? const Center(child: Text('No trips available')) // Message when no trips are available
              : ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return TripCard(trip: trip);
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Add Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, // Color when an item is selected
        unselectedItemColor: Colors.grey, // Color for unselected items
        showUnselectedLabels: true, // Show labels for unselected items
        onTap: _onItemTapped, // Handle navigation on item tap
      ),
    );
  }
}
