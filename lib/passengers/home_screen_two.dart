import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'payment_screen.dart';
import 'booking_screen.dart'; // Import your BookingScreen
import 'notifications_screen.dart'; // Import your NotificationsScreen
import 'profile_screen.dart'; // Import your ProfileScreen

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({Key? key}) : super(key: key);

  @override
  _PassengerHomeScreenState createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _selectedIndex = 0;
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
        Uri.parse('http://192.168.1.69:5000/bookings'),
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
  void navigateToPaymentScreen(int bookingId, int tripId, String driverName, String destination, double amount, int driverId) async {
    if (amount <= 0) {
      print('Invalid amount: $amount for Trip ID: $tripId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid payment amount.')),
      );
      return;
    }

    // Proceed to the payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          bookingId: bookingId, // Pass bookingId here
        
          driverName: driverName,
          destination: destination,
          amount: amount,
          
        ),
      ),
    );
  }

  // Handle bottom navigation item taps
  void _onItemTapped(int index) {
    switch (index) {
      case 0: // Home
        setState(() {
          _selectedIndex = index; // Update selected index
        });
        break;
      case 1: // Booking
        Navigator.pushReplacementNamed(context, '/booking');
        break;
      case 2: // Notifications
        _navigateToNotifications(); // Navigate to notifications
        break;
      case 3: // Account
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

                    // Safely fetch the amount ensuring it's a valid number
                    double amount = 0.0;
                    if (booking['amount'] != null) {
                      try {
                        amount = double.parse(booking['amount'].toString());
                      } catch (e) {
                        print('Error parsing amount: $e');
                      }
                    }

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
                            Text('Amount: \$${amount.toStringAsFixed(2)}'), // Display the amount correctly
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
                              amount,
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
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Call the navigation logic
      ),
    );
  }
}
