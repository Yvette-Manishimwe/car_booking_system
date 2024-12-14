import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import for secure storage

class BookingConfirmationScreen extends StatefulWidget {
  final int tripId;
  final int driverId;
  final int passengerId; // Add passengerId parameter

  const BookingConfirmationScreen({
    super.key,
    required this.tripId,
    required this.driverId,
    required this.passengerId, // Add to constructor
  });

  @override
  _BookingConfirmationScreenState createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _tripTime = ''; // Variable to hold selected trip time
  int availableSeats = 0; // Variable to hold available seats

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchAvailableSeats(); // Fetch available seats when the screen loads
  }

  Future<void> _fetchAvailableSeats() async {
    final url = Uri.parse('http://192.168.149.59:5000/get_trip_details/${widget.tripId}'); // Replace with your endpoint
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          availableSeats = data['data']['available_seats'] ?? 0; 
        });
      } else {
        print('Failed to load trip details');
      }
    } catch (e) {
      print('Error fetching trip details: $e');
    }
  }

  Future<void> _confirmBooking() async {
    final url = Uri.parse('http://192.168.149.59:5000/book_trip');

    // Retrieve the JWT token from secure storage
    String? token = await _secureStorage.read(key: 'token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final bookingData = {
      'trip_id': widget.tripId,
      'passenger_id': widget.passengerId, // Use the passenger ID passed from BookingScreen
      'number_of_seats': int.parse(_seatsController.text),
      'booking_time': _tripTime, // Use the selected trip time
      'passenger_name': _nameController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(bookingData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking successful!')),
        );
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book trip: Not enough available seats')),
        );
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access Denied: Invalid Token')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book trip')),
        );
      }
    } catch (e) {
      print('Error confirming booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error confirming booking')),
      );
    }
  }

  Future<void> _selectDateAndTime() async {
    // Show date picker
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      // Show time picker
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        // Format the date and time to your desired format
        setState(() {
          _tripTime = '${selectedDate.toLocal()} ${selectedTime.format(context)}'; // Store selected date and time
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card to display available seats
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Available Seats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$availableSeats',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input fields for booking details
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seatsController,
              decoration: const InputDecoration(
                labelText: 'Number of Seats',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Trip Time selection button
            GestureDetector(
              onTap: _selectDateAndTime, // Call the date and time picker
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _tripTime.isNotEmpty ? _tripTime : 'Select Trip Time',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Booking Button
            ElevatedButton(
              onPressed: _confirmBooking,
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _seatsController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
