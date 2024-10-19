import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  _EarningsScreenState createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  double totalEarnings = 0.0;
  double averageRating = 0.0;
  bool isLoading = true;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(); // Secure storage instance
  int _selectedIndex = 2; // Set initial index to 2 (Earnings)

  @override
  void initState() {
    super.initState();
    fetchEarnings();
  }

  Future<void> fetchEarnings() async {
    try {
      // Retrieve the token from secure storage
      final String? token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('No auth token found');
      }

      // Perform the HTTP GET request to fetch earnings data
      final response = await http.get(
        Uri.parse('http://192.168.1.70:5000/earnings'),
        headers: {
          'Authorization': 'Bearer $token', // Use the token from secure storage
          'Content-Type': 'application/json',
        },
      );

      // Ensure the status code is 200 (OK) before proceeding
      if (response.statusCode == 200) {
        // Parse the response body
        final data = json.decode(response.body);
        setState(() {
          totalEarnings = double.tryParse(data['totalEarnings'].toString()) ?? 0.0;
          averageRating = double.tryParse(data['averageRating'].toString()) ?? 0.0;
          isLoading = false;
        });
      } else {
        // Handle non-200 responses
        throw Exception('Failed to load earnings');
      }
    } catch (e) {
      // Handle any errors that occur during the fetch
      print('Error fetching earnings: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the selected screen based on the index
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/'); // Replace with your home screen route
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/add-trip'); // Replace with your add trip screen route
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/earning'); // Replace with your earnings screen route
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/drivers_notification'); // Replace with your notifications screen route
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/account'); // Replace with your account screen route
        break;
    }
  }

  Future<bool> _onWillPop() async {
    // Navigate to the home page
    Navigator.pushReplacementNamed(context, '/');
    return false; // Prevent default back button behavior
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle back button press
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Earnings of the Day'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEarningsCard('Total Earnings:', '\$${totalEarnings.toStringAsFixed(2)}'),
                    const SizedBox(height: 20),
                    _buildEarningsCard('Average Rating:', '${averageRating.toStringAsFixed(1)} stars'),
                  ],
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex, // Set the current selected index
          onTap: _onItemTapped, // Handle navigation on item tap
          selectedItemColor: Colors.blue, // Color when an item is selected
          unselectedItemColor: Colors.grey, // Color for unselected items
          showUnselectedLabels: true, // Show labels for unselected items
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
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

  Widget _buildEarningsCard(String title, String amount) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ) ??
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 34,
                  ) ??
                  const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
