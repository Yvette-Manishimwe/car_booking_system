import 'package:flutter/material.dart';

class UserTripsScreen extends StatefulWidget {
  const UserTripsScreen({super.key});

  @override
  _UserTripsScreenState createState() => _UserTripsScreenState();
}

class _UserTripsScreenState extends State<UserTripsScreen> {
  // Sample data of trips
  List<Map<String, String>> trips = [
    {
      'date': 'Sept 7, 2024',
      'pickup': 'Location A',
      'dropoff': 'Location B',
      'status': 'Completed',
      'fare': '\$25'
    },
    {
      'date': 'Sept 6, 2024',
      'pickup': 'Location C',
      'dropoff': 'Location D',
      'status': 'Cancelled',
      'fare': '\$0'
    },
    {
      'date': 'Sept 5, 2024',
      'pickup': 'Location E',
      'dropoff': 'Location F',
      'status': 'Completed',
      'fare': '\$30'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(
                '${trip['pickup']} to ${trip['dropoff']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${trip['date']}'),
                  Text('Status: ${trip['status']}'),
                  Text('Fare: ${trip['fare']}'),
                ],
              ),
              leading: Icon(
                Icons.directions_car,
                color: trip['status'] == 'Completed' ? Colors.green : Colors.red,
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showTripDetails(trip);
              },
            ),
          );
        },
      ),
    );
  }

  // Method to show details of the trip
  void _showTripDetails(Map<String, String> trip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Trip Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${trip['date']}'),
              Text('Pickup: ${trip['pickup']}'),
              Text('Drop-off: ${trip['dropoff']}'),
              Text('Status: ${trip['status']}'),
              Text('Fare: ${trip['fare']}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
