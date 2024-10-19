import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedPickup;
  String? selectedDropoff;

  final List<String> locations = ['Location A', 'Location B', 'Location C', 'Location D'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Select Pickup Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              hint: const Text('Select Pickup'),
              value: selectedPickup,
              items: locations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPickup = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Drop-off Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              hint: const Text('Select Drop-off'),
              value: selectedDropoff,
              items: locations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDropoff = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedPickup != null && selectedDropoff != null
                  ? () {
                      _searchForRides();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Search for Rides'),
            ),
          ],
        ),
      ),
    );
  }

  void _searchForRides() {
    // Simulating ride search based on selected pickup and drop-off locations.
    if (selectedPickup != null && selectedDropoff != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Searching for available rides from $selectedPickup to $selectedDropoff...'),
      ));

      // Implement your backend API call to search for available rides here.
      // You can use Firebase or any backend API to search and display rides.
    }
  }
}
