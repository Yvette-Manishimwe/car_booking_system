import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PassengerDetailsScreen extends StatelessWidget {
  final String passengerName;
  final String passengerLocation;

  const PassengerDetailsScreen({
    Key? key,
    required this.passengerName,
    required this.passengerLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passenger Name: $passengerName', style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            Text('Location: $passengerLocation', style: TextStyle(fontSize: 18)),
            // Add more details as needed
          ],
        ),
      ),
    );
  }
}
