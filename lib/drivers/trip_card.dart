import 'package:drivers_app/drivers/trip_card_details.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripCard({super.key, required this.trip});

  String formatDateTime(String dateTime) {
    DateTime parsedDate = DateTime.parse(dateTime);
    return DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        title: Text('Destination: ${trip['destination']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Departure: ${trip['departure_location']}'),
            Text('Date: ${formatDateTime(trip['trip_time'])}'),
            Text('Available Seats: ${trip['available_seats']}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.details),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailsScreen(tripId: trip['id']),
              ),
            );
          },
        ),
      ),
    );
  }
}
