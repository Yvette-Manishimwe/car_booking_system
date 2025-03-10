import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert' as convert;

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({required this.email, Key? key}) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isVerifying = false;

  Future<void> _verifyOtp() async {
    setState(() {
      _isVerifying = true;
    });

    final Map<String, dynamic> otpData = {
      'email': widget.email,
      'otp': _otpController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.151.247.59:5000/verify-otp'), // Adjust the URL if needed
        headers: {'Content-Type': 'application/json'},
        body: json.encode(otpData),
      );

      setState(() {
        _isVerifying = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String? token = responseData['token'];
        final dynamic passengerId = responseData['passenger_id'];

        if (token != null) {
          await _storage.write(key: 'token', value: token);

          if (passengerId != null) {
            await _storage.write(
              key: 'passenger_id',
              value: passengerId.toString(),
            );
          }

          final payload = token.split('.')[1];
          final String normalizedPayload = _normalizeBase64Url(payload);
          final decodedPayload = convert.utf8.decode(base64Url.decode(normalizedPayload));
          final Map<String, dynamic> decodedData = json.decode(decodedPayload);

          final String role = decodedData['category'];

          if (role == 'Driver') {
            Navigator.of(context).pushReplacementNamed('/');
          } else if (role == 'Passenger') {
            Navigator.of(context).pushReplacementNamed('/passenger_home');
          } else {
            Fluttertoast.showToast(
              msg: 'Invalid role in token.',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: 'Failed to receive token.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'OTP verification failed: ${response.statusCode}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (error) {
      setState(() {
        _isVerifying = false;
      });
      Fluttertoast.showToast(
        msg: 'An error occurred: $error',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  String _normalizeBase64Url(String base64Url) {
    int paddingLength = 4 - (base64Url.length % 4);
    if (paddingLength != 4) {
      base64Url += '=' * paddingLength;
    }
    return base64Url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter the 6-digit OTP sent to your email:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _isVerifying
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      child: const Text('Verify OTP'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
