import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final int tripId;
  final int driverId;
  final int passengerId;

  const BookingConfirmationScreen({
    super.key,
    required this.tripId,
    required this.driverId,
    required this.passengerId,
  });

  @override
  _BookingConfirmationScreenState createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bookingTimeController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  int availableSeats = 0;

  @override
  void initState() {
    super.initState();
    _fetchAvailableSeats();
  }

  Future<void> _fetchAvailableSeats() async {
    final url = Uri.parse('http://10.151.247.59:5000/get_trip_details/${widget.tripId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          availableSeats = data['data']['available_seats'] ?? 0;
        });
      } else {
        _showSnackBar('Failed to load trip details');
      }
    } catch (e) {
      _showSnackBar('Error fetching trip details: $e');
    }
  }

Future<void> _selectDateTime() async {
  DateTime now = DateTime.now();

  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: now, // Prevent selecting past dates
    lastDate: DateTime(2101),
  );

  if (pickedDate != null) {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      DateTime combinedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // Ensure the selected datetime is in the future
      if (combinedDateTime.isAfter(now)) {
        final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
        setState(() {
          _bookingTimeController.text = formattedDateTime;
        });
      } else {
        // Show error if user selects a past time
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a future time.')),
        );
      }
    }
  }
}

  Future<void> _confirmBooking() async {
    final url = Uri.parse('http://10.151.247.59:5000/book_trip');
    String? token = await _secureStorage.read(key: 'token');

    if (token == null) {
      _showSnackBar('User not authenticated');
      return;
    }

    final bookingData = {
      'trip_id': widget.tripId,
      'passenger_id': widget.passengerId,
      'number_of_seats': int.tryParse(_seatsController.text) ?? 0,
      'passenger_name': _nameController.text,
      'booking_time': _bookingTimeController.text,
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
        _showSnackBar('Booking successful!');
      } else if (response.statusCode == 400) {
        _showSnackBar('Failed to book trip: Not enough available seats');
      } else if (response.statusCode == 403) {
        _showSnackBar('Access Denied: Invalid Token');
      } else {
        _showSnackBar('Failed to book trip');
      }
    } catch (e) {
      _showSnackBar('Error confirming booking: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            _buildAvailableSeatsCard(),
            const SizedBox(height: 20),
            _buildInputFields(),
            const SizedBox(height: 16),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableSeatsCard() {
    return Card(
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
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
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
        TextField(
          controller: _bookingTimeController,
          decoration: InputDecoration(
            labelText: 'Booking Time',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: _selectDateTime,
            ),
          ),
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _confirmBooking,
      child: const Text('Confirm Booking'),
    );
  }

  @override
  void dispose() {
    _seatsController.dispose();
    _nameController.dispose();
    _bookingTimeController.dispose();
    super.dispose();
  }
}
