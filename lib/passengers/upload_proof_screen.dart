import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadProofScreen extends StatefulWidget {
  final int bookingId;
  final String driverName;
  final String destination;

  const UploadProofScreen({
    super.key,
    required this.bookingId,
    required this.driverName,
    required this.destination,
  });

  @override
  _UploadProofScreenState createState() => _UploadProofScreenState();
}

class _UploadProofScreenState extends State<UploadProofScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  double? _rating;
  bool ratingSubmitted = false;
  bool proofUploaded = false;

  File? _selectedFile;

  // Pick image from gallery or camera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  // Upload proof of payment
  Future<void> _uploadProof() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload')),
      );
      return;
    }

    String? token = await _storage.read(key: 'token');
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.151.247.59:5000/upload_proof/${widget.bookingId}'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'proofOfPayment',
      _selectedFile!.path,
    ));

    final response = await request.send();

    if (response.statusCode == 200) {
      setState(() {
        proofUploaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof of payment uploaded successfully!')),
      );

      // Verify payment after uploading proof
      _verifyPayment();
    } else {
      final responseBody = await response.stream.bytesToString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload proof: $responseBody')),
      );
    }
  }

  // Verify payment status
  Future<void> _verifyPayment() async {
    String? token = await _storage.read(key: 'token');

    final response = await http.post(
      Uri.parse('http://10.151.247.59:5000/verify_payment/${widget.bookingId}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment verified successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify payment: ${response.body}')),
      );
    }
  }

  // Check if rating is already submitted
  Future<void> _checkRatingSubmission() async {
    String? token = await _storage.read(key: 'token');

    final response = await http.get(
      Uri.parse('http://10.151.247.59:5000/check_rating?booking_id=${widget.bookingId}'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        ratingSubmitted = data['ratingSubmitted'] ?? false;
      });

      if (ratingSubmitted) {
        Navigator.pop(context); // Navigate to home if already rated
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check rating status: ${response.body}')),
      );
    }
  }

  // Submit driver rating
  Future<void> _submitRating() async {
    String? token = await _storage.read(key: 'token');

    final response = await http.post(
      Uri.parse('http://10.151.247.59:5000/rate_driver'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'booking_id': widget.bookingId,
        'rating': _rating,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        ratingSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating submitted successfully!')),
      );
      Navigator.pop(context); // Navigate back after submission
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: ${response.body}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkRatingSubmission();
  }

  Widget buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < (_rating ?? 0) ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1.0;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Proof & Rate Driver'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload Proof of Payment:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 10),
            if (_selectedFile != null)
              Text('Selected file: ${_selectedFile!.path}'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: proofUploaded ? null : _uploadProof,
              child: const Text('Upload Proof'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rate the Driver:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            buildStarRating(),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _rating == null || ratingSubmitted
                  ? null
                  : _submitRating,
              child: const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }
}
