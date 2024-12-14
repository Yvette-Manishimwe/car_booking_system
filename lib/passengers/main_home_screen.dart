import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  _MainHomeScreenState createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isLoading = true;
  List trips = []; // List to store trips data
  int? _loggedInPassengerId;
  int _currentIndex = 0; // Track the current tab index

  @override
  void initState() {
    super.initState();
    fetchAvailableTrips();
    _fetchLoggedInPassengerId();
  }

  Future<void> _fetchLoggedInPassengerId() async {
    try {
      // Retrieve the passenger ID from secure storage
      final String? passengerId = await _storage.read(key: 'passenger_id');
      setState(() {
        _loggedInPassengerId = passengerId != null ? int.parse(passengerId) : null;
      });

      if (_loggedInPassengerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger ID not found. Please log in again.')),
        );
      }
    } catch (e) {
      print('Error fetching passenger ID: $e');
    }
  }

  Future<void> fetchAvailableTrips() async {
    try {
      // Retrieve the token from secure storage
      final String? token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('http://192.168.149.59:5000/available-trips'),
        headers: {
          'Authorization': 'Bearer $token', // Use the token from secure storage
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          trips = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load available trips');
      }
    } catch (e) {
      print('Error fetching trips: $e');
      Fluttertoast.showToast(msg: "Error fetching trips. Please try again.");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onBookButtonPressed(int tripId) {
    if (_loggedInPassengerId != null) {
      // Navigate to the booking screen with the selected trip ID and passenger ID
      Navigator.pushNamed(
        context,
        '/booking',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger ID not found. Please log in again.')),
      );
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Stay on current page (Home)
        break;
      case 1:
        Navigator.pushNamed(context, '/booking');
        break;
      case 2:
        Navigator.pushNamed(context, '/payment');
        break;
      case 3:
        Navigator.pushNamed(context, '/notification');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                var trip = trips[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    title: Text(
                      'Destination: ${trip['destination']}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Departure Time: ${trip['departure_time']}'),
                        Text('Available Seats: ${trip['available_seats']}'),
                        Text(
                          'Driver: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${trip['driver_name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Contact: ${trip['driver_phone']}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _onBookButtonPressed(trip['trip_id']),
                      child: const Text('Book'),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payment',
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}
