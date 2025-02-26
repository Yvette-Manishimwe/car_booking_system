import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'booking_confirmation_screen.dart';
import 'package:intl/intl.dart';

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
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _fetchLoggedInPassengerId();
  }

  Future<void> _fetchLoggedInPassengerId() async {
    try {
      final storage = FlutterSecureStorage();
      String? passengerId = await storage.read(key: 'passenger_id');
      setState(() {
        _loggedInPassengerId =
            passengerId != null ? int.parse(passengerId) : null;
      });
      if (_loggedInPassengerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Passenger ID not found. Please log in again.')),
        );
      }
    } catch (e) {
      print('Error fetching passenger ID: $e');
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.151.247.59:5000/locations'),
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
  if (_selectedDepartureLocation == null || _selectedDestination == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select both locations')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.get(
      Uri.parse(
          'http://10.151.247.59:5000/available_drivers?departure_location=$_selectedDepartureLocation&destination=$_selectedDestination'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      setState(() {
        _availableDrivers = data['drivers'];
        _isLoading = false;
      });

      if (data.containsKey('message')) {
        // Show the backend message when no drivers are available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } else {
      print('Failed to load available drivers');
      setState(() {
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Error fetching available drivers: $e');
    setState(() {
      _isLoading = false;
    });
  }
}


  // Handle navigation when a BottomNavigationBar item is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/passenger_home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/booking');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/payment');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notification');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      default:
        throw Exception('Invalid index');
    }
  }

  void _navigateToBookingConfirmationScreen(dynamic driver) {
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
        const SnackBar(
            content: Text('Passenger ID not found. Please log in again.')),
      );
    }
  }

  String formatDateTime(String dateTime) {
    DateTime parsedDate = DateTime.parse(dateTime);
    return DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
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
              decoration:
                  const InputDecoration(labelText: 'Departure Location'),
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
                        leading: CircleAvatar(
                          radius: 35.0, // Increased radius for a bigger image
                          backgroundImage: NetworkImage(
                            'http://10.151.247.59:5000${driver['profile_picture']}' ??
                                'assets/default_profile_picture.jpg',
                          ),
                        ),
                        title: Text(driver['name']),
                        subtitle: Text(
                          'Plate: ${driver['plate_number']} , '
                          'Time: ${formatDateTime(driver['trip_time'])}, ' // Formatting the time
                          'Destination: ${driver['destination']}, '
                          'Departure: ${driver['departure_location']}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () =>
                              _navigateToBookingConfirmationScreen(driver),
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
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
