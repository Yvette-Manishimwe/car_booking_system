import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  _PassengerProfileScreenState createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  String passengerName = '';
  String passengerEmail = '';
  String passengerPhone = '';
  String passengerCategory = '';
  String passengerProfilePictureUrl = ''; // To hold profile picture URL
  bool isLoading = true;
  int _selectedIndex = 4; // Default index for the bottom navigation bar

  final FlutterSecureStorage _storage = const FlutterSecureStorage(); // Secure storage instance

  @override
  void initState() {
    super.initState();
    fetchPassengerDetails();
  }

  Future<void> fetchPassengerDetails() async {
    try {
      // Retrieve the token from secure storage
      final String? token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('http://192.168.149.59:5000/passenger-details'),
        headers: {
          'Authorization': 'Bearer $token', // Use the token from secure storage
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          passengerName = data['name'] ?? 'No Name Available';
          passengerEmail = data['email'] ?? 'No Email Available';
          passengerPhone = data['phone'] ?? 'No Phone Available';
          passengerCategory = data['category'] ?? 'No Category Available';
          passengerProfilePictureUrl = data['profile_picture'] != null 
              ? 'http://192.168.149.59:5000/${data['profile_picture']}'  // Replace with your actual IP address
              : ''; // Make sure to set it as empty if no profile picture URL is found
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Failed to load passenger details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching passenger details: $e');
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('An unexpected error occurred: $e');
    }
  }

  Future<void> logout() async {
    // Clear the token from secure storage
    await _storage.delete(key: 'token');

    // Navigate to the login page
    Navigator.pushReplacementNamed(context, '/signin');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/passenger_home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/booking');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/payment');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/notification');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      default:
        throw Exception('Invalid index');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout, // Logout button
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Profile card with profile picture and details
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Profile picture inside the card
                          if (passengerProfilePictureUrl.isNotEmpty)
                            CircleAvatar(
                              radius: 50.0,
                              backgroundImage: passengerProfilePictureUrl.isNotEmpty
                                ? NetworkImage(passengerProfilePictureUrl)
                                : const AssetImage('assets/default_profile.png') as ImageProvider,
                            ),
                          const SizedBox(height: 16),
                          // Profile information
                          Column(
                            children: [
                              Center(
                                child: Text(
                                  'Name:',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(
                                child: Text(
                                  passengerName,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'Email:',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(
                                child: Text(
                                  passengerEmail,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'Phone:',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(
                                child: Text(
                                  passengerPhone,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'Category:',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Center(
                                child: Text(
                                  passengerCategory,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Earning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey, // Keep unselected tabs visible
        onTap: _onItemTapped,
      ),
    );
  }
}
