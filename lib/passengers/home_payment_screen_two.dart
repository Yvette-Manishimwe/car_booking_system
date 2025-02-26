import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'payment_screen.dart';
import 'booking_screen.dart'; // Import your BookingScreen
import 'notifications_screen.dart'; // Import your NotificationsScreen
import 'profile_screen.dart'; // Import your ProfileScreen

class HomePaymentScreenTwo extends StatefulWidget {
  const HomePaymentScreenTwo({Key? key}) : super(key: key);

  @override
  _HomePaymentScreenTwoState createState() => _HomePaymentScreenTwoState();
}

class _HomePaymentScreenTwoState extends State<HomePaymentScreenTwo> {
  int _selectedIndex = 2;
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Fetch the logged-in passenger ID from secure storage
  Future<int?> _fetchLoggedInPassengerId() async {
    String? passengerId = await _storage.read(key: 'passenger_id'); // Replace with your actual key
    return passengerId != null ? int.parse(passengerId) : null;
  }

  // Navigate to Notifications
  void _navigateToNotifications() async {
    int? passengerId = await _fetchLoggedInPassengerId(); // Fetch the ID asynchronously
    if (passengerId != null) {
      Navigator.pushNamed(context, '/notification'); // No need to pass passengerId
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passenger ID not found')),
      );
    }
  }

  // Fetch the list of bookings from the server
  Future<void> fetchBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final response = await http.get(
        Uri.parse('http://10.151.247.59:5000/bookings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Fetched bookings: $data'); // Check the fetched data

        setState(() {
          bookings = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load bookings. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBookings(); // Fetch bookings on screen load
  }

  // Navigate to PaymentScreen with bookingId
  void navigateToPaymentScreen(int bookingId, int tripId, String driverName, String destination, int driverId) async {
 

    // Proceed to the payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          bookingId: bookingId, // Pass bookingId here
        
          driverName: driverName,
          destination: destination,
          
        ),
      ),
    );
  }

  // Handle bottom navigation item taps
  void _onItemTapped(int index) {
    switch (index) {
      case 0: // Home
         Navigator.pushReplacementNamed(context, '/passenger_home');
        break;
      case 1: // Booking
        Navigator.pushReplacementNamed(context, '/booking');
        break;
      case 2:
               setState(() {
          _selectedIndex = index; // Update selected index
        });
      case 3: // Notifications
        _navigateToNotifications(); // Navigate to notifications
        break;
      case 4: // Account
        Navigator.pushReplacementNamed(context, '/profile'); // Navigate to ProfileScreen
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Bookings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? const Center(child: Text('No bookings available'))
              : ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];

                    

                    // Assuming the driver ID is available in the booking object
                    int driverId = booking['driver_id'] ?? 0; // Use 0 as default if not available

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        title: Text('Booking ID: ${booking['booking_id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trip ID: ${booking['trip_id']}'),
                            Text('Driver: ${booking['driver_name']}'),
                            Text('Destination: ${booking['destination']}'),
                            Text('Departure: ${booking['departure_location']}'),
                            Text('Available Seats: ${booking['available_seats']}'),
                            Text('Booking Time: ${booking['booking_time']}'),
                            Text('Booked seats: ${booking['booked_seats']}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            navigateToPaymentScreen(
                              booking['booking_id'], // Pass bookingId
                              booking['trip_id'],
                              booking['driver_name'],
                              booking['destination'],
                              driverId, // Pass the driver ID here
                            );
                          },
                          child: const Text('Pay'),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payment'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Call the navigation logic
      ),
    );
  }
}
