import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId; // Booking ID passed from a previous screen
  final String driverName; // Driver name for the trip
  final String destination; // Destination for the trip
  final double amount; // Amount for the trip

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.driverName,
    required this.destination,
    required this.amount,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isTripOver = false;
  bool ratingSubmitted = false; // Track if the rating has been submitted
  double? _rating;

  @override
  void initState() {
    super.initState();
    _checkRatingSubmission();
  }

  // Check if the rating has already been submitted based on booking_id
  Future<void> _checkRatingSubmission() async {
    String? token = await _storage.read(key: 'token');

    final response = await http.get(
      Uri.parse('http://192.168.1.69:5000/check_rating?booking_id=${widget.bookingId}'),
      headers: {
        'Authorization': 'Bearer $token', // Include the token in the headers
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        ratingSubmitted = data['ratingSubmitted'] ?? false; // Check API response
      });
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check rating status: ${response.body}')),
      );
    }
  }

  // Handle rating submission based on booking_id
  Future<void> _submitRating(double rating) async {
    String? token = await _storage.read(key: 'token');

    final response = await http.post(
      Uri.parse('http://192.168.1.69:5000/rate_driver'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Include the token in the headers
      },
      body: jsonEncode({
        'booking_id': widget.bookingId, // Use booking_id for rating
        'rating': rating,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        ratingSubmitted = true; // Set the rating as submitted
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: ${response.body}')),
      );
    }
  }

  // Method to build the star rating row
  Widget buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < (_rating ?? 0) ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1.0; // Set rating based on the star clicked
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment & Rating'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Current Trip Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Booking ID: ${widget.bookingId}'),
            Text('Driver Name: ${widget.driverName}'),
            Text('Destination: ${widget.destination}'),
            Text('Amount: \$${widget.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 20),

            if (ratingSubmitted) ...[ // If the rating is already submitted
              const Text(
                'You have already paid for this trip. Please go back to the home screen.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/passenger_home'); // Navigate to the home screen
                },
                child: const Text('Go to Home'),
              ),
            ] else ...[ // If the rating is not submitted yet
              const Text(
                'Please pay using the code: *182*4#',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rate the driver:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              buildStarRating(), // Display star rating here
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _rating == null
                    ? null
                    : () {
                        _submitRating(_rating!);
                      },
                child: const Text('Submit Rating'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
