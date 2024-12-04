import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int _selectedIndex = 3; // Set default index for Notifications

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      String? token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.69:5000/get_notifications'), // Updated URL
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('Fetched notifications: $data');

        setState(() {
          notifications = List<Map<String, dynamic>>.from(data);
          isLoading = false; // Set loading to false after fetching
        });
      } else {
        throw Exception('Failed to load notifications. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        isLoading = false; // Set loading to false on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  // Handle bottom navigation item taps
  void _onItemTapped(int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, '/passenger_home'); // Navigate to HomeScreen
        break;
      case 1: // Booking
        Navigator.pushReplacementNamed(context, '/booking'); // Navigate to BookingScreen
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/payment'); 
        break;
      case 3: // Notifications (current screen)
        break; 
      case 4: // Account
        Navigator.pushReplacementNamed(context, '/profile'); // Navigate to ProfileScreen
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text('No notifications available'))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: ListTile(
                        title: Text(notification['message'] ?? 'No message'), // Safeguard against null
                        subtitle: Text(notification['timestamp'] ?? 'No timestamp'), // Safeguard against null
                        trailing: Icon(
                          notification['status'] == 'Confirmed'
                              ? Icons.check
                              : Icons.new_releases,
                          color: notification['status'] == 'Confirmed' ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payment'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Call the navigation logic
      ),
    );
  }
}
