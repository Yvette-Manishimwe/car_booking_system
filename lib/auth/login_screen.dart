import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'signup_screen.dart'; // Assuming you have this screen for the signup

class LoginsScreen extends StatefulWidget {
  const LoginsScreen({super.key});

  @override
  _LoginsScreenState createState() => _LoginsScreenState();
}

class _LoginsScreenState extends State<LoginsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  String? _errorMessage;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _login() async {
    setState(() {
      _isLoggingIn = true; // Show loading indicator
      _errorMessage = null; // Reset any previous error message
    });

    try {
      // Prepare the login data
      final Map<String, String> loginData = {
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      // Send the login request to the API
      final response = await http.post(
        Uri.parse('http://192.168.1.70:5000/login-passenger'), // Your API endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );

      // Check for success
      if (response.statusCode == 200) {
        // Parse response and store token if available
        final responseData = json.decode(response.body);
        final token = responseData['token']; // Assuming your API returns a token

        // Store the token securely
        await _storage.write(key: 'token', value: token);

        // Navigate to the passenger dashboard or main screen
        Navigator.of(context).pushReplacementNamed('/passenger_home');
      } else {
        // Handle errors based on response
        final errorResponse = json.decode(response.body);
        setState(() {
          _errorMessage = errorResponse['message'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
      print('Login error: $error');
    } finally {
      setState(() {
        _isLoggingIn = false; // Hide loading indicator
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // Padding around the login form
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Login Container
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26, // Shadow effect
                      blurRadius: 8.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Login Title
                    const Text(
                      'Passenger Login',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error Message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Login Button
                    SizedBox(
                      width: double.infinity, // Full-width button
                      child: ElevatedButton(
                        onPressed: _isLoggingIn ? null : _login, // Disable button when logging in
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: Colors.black, // Dark button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _isLoggingIn
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sign-Up Text
                    GestureDetector(
                      onTap: () {
                        // Navigate to the Sign-Up screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
