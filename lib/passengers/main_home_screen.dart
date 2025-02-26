import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  _MainHomeScreenState createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isLoading = true;
  List trips = [];
  int? _loggedInPassengerId;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchLoggedInPassengerId();
    _fetchAvailableTrips();
  }

  Future<void> _fetchLoggedInPassengerId() async {
    try {
      final String? passengerId = await _storage.read(key: 'passenger_id');
      setState(() {
        _loggedInPassengerId = passengerId != null ? int.parse(passengerId) : null;
      });
      if (_loggedInPassengerId == null) {
        _showSnackbar('Passenger ID not found. Please log in again.');
      }
    } catch (e) {
      debugPrint('Error fetching passenger ID: $e');
    }
  }

  Future<void> _fetchAvailableTrips() async {
    try {
      final String? token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('http://10.151.247.59:5000/available-trips'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          trips = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load available trips');
      }
    } catch (e) {
      debugPrint('Error fetching trips: $e');
      Fluttertoast.showToast(msg: 'Error fetching trips. Please try again.');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onBookButtonPressed(int tripId) {
    if (_loggedInPassengerId != null) {
      Navigator.pushNamed(context, '/booking', arguments: {
        'tripId': tripId,
        'passengerId': _loggedInPassengerId,
      });
    } else {
      _showSnackbar('Passenger ID not found. Please log in again.');
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    final routes = ['/home', '/booking', '/payment', '/notification', '/profile'];
    if (index < routes.length) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  String _formatDepartureTime(String isoTime) {
    try {
      final DateTime parsedTime = DateTime.parse(isoTime);
      return '${parsedTime.year}-${parsedTime.month.toString().padLeft(2, '0')}-${parsedTime.day.toString().padLeft(2, '0')} '
          '${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}:${parsedTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return isoTime;
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? const Center(child: Text('No available trips found.'))
              : ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
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
                            Text('Departure: ${trip['departure_location']}'),
                            Text('Departure Time: ${_formatDepartureTime(trip['departure_time'])}'),
                            Text('Available Seats: ${trip['available_seats']}'),
                            const Text(
                              'Driver:',
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
