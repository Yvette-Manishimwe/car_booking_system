import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  _AddTripScreenState createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _tripTimeController = TextEditingController();
  final TextEditingController _availableSeatsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isSubmitting = false;
  String? _selectedDeparture;
  String? _selectedDestination;

  List<String> _locations = [];
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.69:5000/locations'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _locations = List<String>.from(data['locations']);
          _isLoadingLocations = false;
        });
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      print('Error fetching locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _tripTimeController.dispose();
    _availableSeatsController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitTrip() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final String? token = await _storage.read(key: 'token');
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unauthorized. Please log in.')),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        Map<String, dynamic> tripData = {
          'plate_number': _plateNumberController.text,
          'destination': _selectedDestination,
          'departure_location': _selectedDeparture,
          'trip_time': _tripTimeController.text,
          'available_seats': int.parse(_availableSeatsController.text),
          'amount': double.parse(_amountController.text),
        };

        final response = await http.post(
          Uri.parse('http://192.168.1.69:5000/add_trip'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(tripData),
        );

        setState(() {
          _isSubmitting = false;
        });

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip added successfully!')),
          );
          _formKey.currentState!.reset();
          _selectedDeparture = null;
          _selectedDestination = null;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add trip')),
          );
        }
      } catch (error) {
        print('Error submitting trip: $error');
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  Future<void> _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final formattedDateTime = DateFormat('yy-MM-dd HH:mm').format(combinedDateTime);
        _tripTimeController.text = formattedDateTime;
      }
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.popUntil(context, ModalRoute.withName('/'));
        break;
      case 1:
        // Stay on Add Trip page
        break;
      case 2:
        Navigator.pushNamed(context, '/earning');
        break;
      case 3:
        Navigator.pushNamed(context, '/drivers_notification');
        break;
      case 4:
        Navigator.pushNamed(context, '/account');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popUntil(context, ModalRoute.withName('/'));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Trip'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // Allow scrolling
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _plateNumberController,
                    decoration: const InputDecoration(labelText: 'Plate Number'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter plate number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedDeparture,
                    items: _locations
                        .map((location) => DropdownMenuItem(
                              value: location,
                              child: Text(location),
                            ))
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Departure Location'),
                    onChanged: (value) {
                      setState(() {
                        _selectedDeparture = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select departure location' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedDestination,
                    items: _locations
                        .map((location) => DropdownMenuItem(
                              value: location,
                              child: Text(location),
                            ))
                        .toList(),
                    decoration: const InputDecoration(labelText: 'Destination'),
                    onChanged: (value) {
                      setState(() {
                        _selectedDestination = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select destination' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tripTimeController,
                    decoration: InputDecoration(
                      labelText: 'Trip Time',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: _selectDateTime,
                      ),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select trip time';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _availableSeatsController,
                    decoration: const InputDecoration(labelText: 'Available Seats'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter available seats';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount(RWF)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTrip,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text('Add Trip'),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 1,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: 'Add Trip',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
