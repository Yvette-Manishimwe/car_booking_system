import 'package:drivers_app/auth/otp_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoggingIn = false;

  Future<void> _signin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoggingIn = true;
      });

      // User login data
      Map<String, dynamic> loginData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'category': 'Driver', // Set 'Passenger' or 'Driver' as needed
      };

      try {
        final response = await http.post(
          Uri.parse('http://192.168.1.69:5000/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(loginData),
        );

        setState(() {
          _isLoggingIn = false;
        });

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your email.')),
          );

          // Navigate to OTP verification screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(email: _emailController.text),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${response.statusCode}')),
          );
        }
      } catch (error) {
        setState(() {
          _isLoggingIn = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Driver Login',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _isLoggingIn
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _signin,
                          child: const Text('Login'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
