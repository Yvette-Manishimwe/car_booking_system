import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(); // Secure storage instance

  bool _isLoggingIn = false;

  Future<void> _signin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoggingIn = true;
      });

      // User login data to send to the backend
      Map<String, dynamic> loginData = {
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      try {
        // Make the HTTP request to your backend API
        final response = await http.post(
          Uri.parse('http://192.168.1.75:5000/login-driver'), // Updated to driver login API
          headers: {'Content-Type': 'application/json'},
          body: json.encode(loginData),
        );

        setState(() {
          _isLoggingIn = false;
        });

        if (response.statusCode == 200) {
          // Parse the response
          final Map<String, dynamic> responseData = json.decode(response.body);
          final String? token = responseData['token']; // Extract token

          if (token != null) {
            // Store the token securely
            await _storage.write(key: 'token', value: token);

            // Navigate to the home screen or wherever you need
            Navigator.of(context).pushReplacementNamed('/'); // Driver home route
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Token not received')),
            );
          }
        } else {
          // If the backend returns an error, show the status code and response
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${response.statusCode}')),
          );
        }
      } catch (error) {
        // Handle network errors or other types of errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background as requested
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8), // Semi-transparent box
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Driver Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Email field with icon
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email), // Email icon
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password field with icon
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock), // Password icon
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Error message display or Progress indicator during login
                        _isLoggingIn
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _signin,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  backgroundColor: Colors.grey[850], // Dark button color
                                ),
                                child: const Text('Login', style: TextStyle(color: Colors.white)),
                              ),
                        const SizedBox(height: 10),
                        // Sign-up option
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/register'); // Navigate to signup
                            },
                            child: const Text("Don't have an account? Sign Up"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
