// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class RegisterScreen extends StatefulWidget {
//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _auth = FirebaseAuth.instance;
//   String email = '', password = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Register')),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               onChanged: (value) {
//                 email = value;
//               },
//               decoration: InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               onChanged: (value) {
//                 password = value;
//               },
//               decoration: InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 try {
//                   final newUser = await _auth.createUserWithEmailAndPassword(email: email, password: password);
//                   if (newUser != null) {
//                     Navigator.pop(context);
//                   }
//                 } catch (e) {
//                   print(e);
//                 }
//               },
//               child: Text('Register'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
