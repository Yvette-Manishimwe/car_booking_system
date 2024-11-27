import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'booking_confirmation_screen.dart';
import 'notifications_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? _selectedDepartureLocation;
  String? _selectedDestination;
  List<String> _locations = [];
  List<dynamic> _availableDrivers = [];
  bool _isLoading = false;
  int? _loggedInPassengerId;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _fetchLoggedInPassengerId();
  }

Future<void> _fetchLoggedInPassengerId() async {
  final storage = FlutterSecureStorage();
  String? passengerId = await storage.read(key: 'passenger_id');
  print('Fetched passenger ID: $passengerId'); // Debugging line
  
  setState(() {
    _loggedInPassengerId = passengerId != null ? int.parse(passengerId) : null;
  });
}


  Future<void> _fetchLocations() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.69:5000/locations'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _locations = List<String>.from(data['locations']);
        });
      } else {
        print('Failed to load locations');
      }
    } catch (e) {
      print('Error fetching locations: $e');
    }
  }

  Future<void> _fetchAvailableDrivers() async {
    // Ensure locations are selected
    if (_selectedDepartureLocation == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both locations')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Start loading indicator
    });

    final url =  Uri.parse(
        'http://192.168.1.69:5000/available_drivers?departure_location=$_selectedDepartureLocation&destination=$_selectedDestination');
    
const token = 'token'; // Replace with the actual JWT token

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _availableDrivers = data['drivers'];
          _isLoading = false;
        });
        
        // Check if drivers are found but not matching the route
        if (_availableDrivers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No drivers available for this route')),
          );
        }
      } else {
        print('Failed to load available drivers');
        setState(() {
          _isLoading = false; // Stop loading indicator
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false; // Stop loading indicator
      });
    }
  }

  void _navigateToNotifications() {
    if (_loggedInPassengerId != null) {
      Navigator.pushNamed(
        context,
        '/notification',
        arguments: {'passengerId': _loggedInPassengerId},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger ID not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDepartureLocation,
              hint: const Text('Select Departure Location'),
              items: _locations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartureLocation = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Departure Location'),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedDestination,
              hint: const Text('Select Destination'),
              items: _locations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDestination = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Destination'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _fetchAvailableDrivers,
              child: const Text('Find Available Drivers'),
            ),
            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator()
               
                    
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = _availableDrivers[index];
                          return ListTile(
                            title: Text(driver['name']),
                            subtitle: Text(
                                'Plate: ${driver['plate_number']} - Time: ${driver['trip_time']}'),
                            trailing: ElevatedButton(
                              onPressed: () {
                                if (_loggedInPassengerId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingConfirmationScreen(
                                        tripId: driver['trip_id'],
                                        driverId: driver['id'],
                                        passengerId: _loggedInPassengerId!,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Passenger ID not found')),
                                  );
                                }
                              },
                              child: const Text('Book'),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Booking',
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
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/passenger_home');
          } else if (index == 1) {
            // Stay on this screen as it's BookingScreen
          } else if (index == 2) {
            _navigateToNotifications();
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
