import 'package:drivers_app/drivers/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DriverNotificationScreen extends StatefulWidget {
  const DriverNotificationScreen({super.key});

  @override
  _DriverNotificationScreenState createState() =>
      _DriverNotificationScreenState();
}

class _DriverNotificationScreenState extends State<DriverNotificationScreen> {
  List<NotificationModel> notifications = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isLoading = true;
  int _selectedIndex = 3; // Index for "Notifications" tab

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final String? token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('http://192.168.149.59:5000/driver-notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          notifications =
              data.map((json) => NotificationModel.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> sendMessage(
      int notificationId, int tripId, String message) async {
    try {
      final String? token = await _storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('http://192.168.149.59:5000/send-message'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'notification_id': notificationId,
          'trip_id': tripId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully')),
        );
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending message')),
      );
    }
  }

  void _showSendMessageDialog(NotificationModel notification) {
    final TextEditingController messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Passenger: ${notification.passengerName}'),
              Text('Phone: ${notification.passengerPhone}'),
              Text('From: ${notification.departure}'),
              Text('To: ${notification.destination}'),
              const SizedBox(height: 10),
              const Text('Send a Message:'),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(hintText: 'Enter your message'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (messageController.text.isNotEmpty) {
                  sendMessage(notification.id, notification.tripId,
                      messageController.text);
                }
              },
              child: const Text('Send'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Driver Notifications'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? const Center(child: Text('No notifications found'))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        title: Text(notification.message),
                        subtitle: Text(notification.timestamp),
                        trailing: IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () {
                            _showSendMessageDialog(notification);
                          },
                        ),
                      );
                    },
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
}
