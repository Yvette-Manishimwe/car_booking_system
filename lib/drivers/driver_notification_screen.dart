import 'package:drivers_app/drivers/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DriverNotificationScreen extends StatefulWidget {
  const DriverNotificationScreen({super.key});

  @override
  _DriverNotificationScreenState createState() => _DriverNotificationScreenState();
}

class _DriverNotificationScreenState extends State<DriverNotificationScreen> {
  List<NotificationModel> notifications = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final String? token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('http://192.168.1.69:5000/driver-notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
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

  Future<void> sendMessage(int notificationId, int tripId, String message) async {
    try {
      final String? token = await _storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('http://192.168.1.69:5000/send-message'),
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
                  sendMessage(notification.id, notification.tripId, messageController.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
