import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TripDetailsScreen extends StatefulWidget {
  final int tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  _TripDetailsScreenState createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late Future<TripDetails> tripDetails;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    tripDetails = fetchTripDetails(widget.tripId);
  }

  Future<TripDetails> fetchTripDetails(int tripId) async {
    final String token = await storage.read(key: 'token') ?? '';

    final response = await http.get(
      Uri.parse('http://192.168.1.69:5000/trip-details/$tripId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return TripDetails.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load trip details: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: FutureBuilder<TripDetails>(
        future: tripDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final details = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trip ID: ${details.tripId}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('Destination: ${details.destination}', style: const TextStyle(fontSize: 16)),
                        Text('Departure Location: ${details.departureLocation}', style: const TextStyle(fontSize: 16)),
                        Text('Trip Time: ${details.tripTime}', style: const TextStyle(fontSize: 16)),
                        Text('Plate Number: ${details.plateNumber}', style: const TextStyle(fontSize: 16)),
                        Text('Available Seats: ${details.availableSeats}', style: const TextStyle(fontSize: 16)),
                        Text('Amount: \$${details.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                        Text('Date Created: ${details.dateCreated}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 20),
                        const Text('Passengers:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  // Wrapping DataTable in Flexible to allow proper layout behavior
                  SizedBox(
                    height: 400, // Adjust this value if needed
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Seats Booked')),
                        ],
                        rows: details.passengers.isNotEmpty
                            ? details.passengers.map((passenger) {
                                return DataRow(cells: [
                                  DataCell(Text(passenger.name)),
                                  DataCell(Text('${passenger.seatsBooked}')),
                                ]);
                              }).toList()
                            : [
                                DataRow(cells: [
                                  DataCell(Text('No passengers booked')),
                                  DataCell(Text('0')),
                                ]),
                              ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class TripDetails {
  final int tripId;
  final String destination;
  final String departureLocation;
  final String tripTime;
  final String plateNumber;
  final int availableSeats;
  final double amount;
  final String dateCreated;
  final List<Passenger> passengers;

  TripDetails({
    required this.tripId,
    required this.destination,
    required this.departureLocation,
    required this.tripTime,
    required this.plateNumber,
    required this.availableSeats,
    required this.amount,
    required this.dateCreated,
    required this.passengers,
  });

  factory TripDetails.fromJson(Map<String, dynamic> json) {
    var passengersFromJson = json['passengers'] as List? ?? [];
    List<Passenger> passengerList = passengersFromJson.map((i) => Passenger.fromJson(i)).toList();

    return TripDetails(
      tripId: json['tripId'] ?? 0,
      destination: json['destination'] ?? 'Unknown',
      departureLocation: json['departureLocation'] ?? 'Unknown',
      tripTime: json['tripTime'] ?? 'Unknown',
      plateNumber: json['plateNumber'] ?? 'Unknown',
      availableSeats: json['availableSeats'] ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      dateCreated: json['dateCreated'] ?? 'Unknown',
      passengers: passengerList,
    );
  }
}

class Passenger {
  final int id;
  final String name;
  final int seatsBooked;

  Passenger({required this.id, required this.name, required this.seatsBooked});

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'] != null ? json['id'] as int : 0,
      name: json['name'] ?? 'Unknown', // Ensure names are handled correctly
      seatsBooked: json['seatsBooked'] != null ? json['seatsBooked'] as int : 0, // Set default to 0
    );
  }
}
