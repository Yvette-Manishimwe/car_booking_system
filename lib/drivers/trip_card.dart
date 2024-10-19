import 'package:drivers_app/drivers/trip_card_details.dart';
import 'package:flutter/material.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripCard({super.key, required this.trip});

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
            Text('Date: ${trip['trip_time']}'),
            Text('Available Seats: ${trip['available_seats']}'),
            Text('Price: \$${trip['amount']}'),
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