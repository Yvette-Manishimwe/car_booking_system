import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  _EarningsScreenState createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  double averageRating = 0.0;
  int totalRatings = 0;
  String reminderMessage = '';
  bool isLoading = true;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int _selectedIndex = 2; // Default index for Earnings screen

  @override
  void initState() {
    super.initState();
    fetchEarnings();
    fetchReminders();
  }

  Future<void> fetchEarnings() async {
    try {
      final String? token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('http://192.168.149.59:5000/earnings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        double parsedRating = (data['averageRating'] is int)
            ? (data['averageRating'] as int).toDouble()
            : (data['averageRating'] ?? 0.0);

        setState(() {
          averageRating = parsedRating;
          totalRatings = data['totalRatings'] ?? 0;
        });
      } else {
        throw Exception('Failed to load earnings');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchReminders() async {
    try {
      final String? token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('http://192.168.149.59:5000/earnings-reminders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['reminders'].isNotEmpty) {
          setState(() {
            reminderMessage = data['reminders'][0]['message'] ?? '';
          });
        } else {
          setState(() {
            reminderMessage = 'Remember that after 1 week with a low rating, you will be paused.';
          });
        }
      } else {
        throw Exception('Failed to load reminders');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, '/');
    return false;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Earnings')),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEarningsCard('Average Rating', '${averageRating.toStringAsFixed(1)} ★'),
                    const SizedBox(height: 20),
                    _buildEarningsCard('Total Ratings', '$totalRatings'),
                    const SizedBox(height: 20),
                    _buildReminderCard(reminderMessage),
                  ],
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
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

  Widget _buildEarningsCard(String title, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28)),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(String message) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
