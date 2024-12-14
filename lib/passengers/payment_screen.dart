import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'upload_proof_screen.dart'; // Import the UploadProofScreen if needed

class PaymentScreen extends StatefulWidget {
  final int bookingId; // Booking ID passed from a previous screen
  final String driverName; // Driver name for the trip
  final String destination; // Destination for the trip

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.driverName,
    required this.destination,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isTripOver = false;
  bool ratingSubmitted = false;
  double? _rating;

  final List<Map<String, dynamic>> _locationsAndAmounts = [
    {'location': 'Rwaza-Ryabazira', 'amount': 5000},
    {'location': 'Kukaziba-Mukungwa', 'amount': 2500},
    {'location': 'Rwaza-Kukaziba', 'amount': 4000},
    {'location': 'Muhazi-Mukungwa', 'amount': 1500},
    {'location': 'Kukaziba-Ryabazira', 'amount': 1000},
  ];

  @override
  void initState() {
    super.initState();
    _checkRatingSubmission();
  }

  Future<void> _checkRatingSubmission() async {
    String? token = await _storage.read(key: 'token');

    final response = await http.get(
      Uri.parse('http://192.168.149.59:5000/check_rating?booking_id=${widget.bookingId}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        ratingSubmitted = data['ratingSubmitted'] ?? false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check rating status: ${response.body}')),
      );
    }
  }



  Widget buildLocationAmountTable() {
    return Table(
      border: TableBorder.all(),
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Amount',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        ..._locationsAndAmounts.map((data) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(data['location']),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${data['amount']} FRW'),
              ),
            ],
          );
        }).toList(),
      ],
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
            const SizedBox(height: 20),

            if (ratingSubmitted) ...[
              const Text(
                'You have already completed payment for this trip.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/passenger_home');
                },
                child: const Text('Go to Home'),
              ),
            ] else ...[
              const Text(
                'Please pay using code: 182*8*1*563031# \n Names: Asifiwe',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              const SizedBox(height: 20),
              const Text(
                'Available Locations and Amounts:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              buildLocationAmountTable(),
              const SizedBox(height: 20),
 

              ElevatedButton(
                onPressed: () {
                  // Directly navigate to UploadProofScreen and pass required parameters
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UploadProofScreen(
                        bookingId: widget.bookingId,
                        driverName: widget.driverName,
                        destination: widget.destination,
                      ),
                    ),
                  );
                },
                child: const Text('Continue to Upload Payment Proof'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
