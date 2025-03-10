import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String name = '';
  String email = '';
  String phone = '';
  String category = '';
  String profilePictureUrl = ''; // Added to store profile picture URL
  bool isLoading = true;
  int _selectedIndex = 4; // Default index for the bottom navigation bar (account at 5th index)

  final FlutterSecureStorage _storage = const FlutterSecureStorage(); // Secure storage instance

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      // Retrieve the token from secure storage
      final String? token = await _storage.read(key: 'token');

      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('http://10.151.247.59:5000/driver-details'),
        headers: {
          'Authorization': 'Bearer $token', // Use the token from secure storage
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          name = data['name'];
          email = data['email'];
          phone = data['phone'];
          category = data['category'];
          profilePictureUrl = data['profile_picture'] != null 
              ? 'http://:5000${data['profile_picture']}'  // Replace with your actual IP address
                : '';
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load driver details');
      }
    } catch (e) {
      print('Error fetching driver details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    // Clear the token from secure storage
    await _storage.delete(key: 'token');
    
    // Navigate to the login page
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/'); // Home route
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/add-trip');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/earning');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/drivers_notification');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/account');
        break;
      default:
        throw Exception('Invalid index');
    }
  }

  Future<bool> _onWillPop() async {
    // Direct back to the home page
    Navigator.pushReplacementNamed(context, '/');
    return false; // Prevent default behavior (exit app)
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handle the back button press
      child: Scaffold(
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
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile picture
                          CircleAvatar(
                            radius: 50.0,
                            backgroundImage: profilePictureUrl.isNotEmpty
                                ? NetworkImage(profilePictureUrl)
                                : const AssetImage('assets/default_profile.png') , 
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Name:',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 26.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Email:',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 26.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Phone:',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 26.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Category:',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 26.0,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
              icon: Icon(Icons.star_border_outlined),
              label: 'Ratings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications', // Notifications now at 4th position
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Account', // Account now at 5th position
            ),
          ],
        ),
      ),
    );
  }
}
