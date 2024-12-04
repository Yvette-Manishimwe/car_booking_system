
import 'package:drivers_app/auth/login_screen.dart';
import 'package:drivers_app/auth/signin_screen.dart';
import 'package:drivers_app/auth/signup_screen.dart';
import 'package:drivers_app/drivers/account_screen.dart';
import 'package:drivers_app/drivers/add_trip_screen.dart';
import 'package:drivers_app/drivers/driver_notification_screen.dart';
import 'package:drivers_app/drivers/earning_screen.dart';
import 'package:drivers_app/drivers/home_screen.dart';
import 'package:drivers_app/passengers/home_payment_screen_two.dart';
import 'package:drivers_app/passengers/booking_screen.dart';
import 'package:drivers_app/passengers/main_home_screen.dart';
import 'package:drivers_app/passengers/notifications_screen.dart';
import 'package:drivers_app/passengers/payment_screen.dart';
import 'package:drivers_app/passengers/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'splashScreen/welcome_screen.dart';

void main() {
  debugPaintSizeEnabled = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car Booking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/welcome', // Setting the initial route to the Welcome screen
      routes: {
        '/welcome': (context) => const WelcomeScreen(), // Welcome screen (splash or introduction screen)
        '/register': (context) => const SignUpScreen(), // Register screen
        '/login': (context) => const SignInScreen(),    // Login screen
        '/': (context) => const HomeScreen(),            // Main app screen after login
        '/account': (context) => const AccountScreen(),  // Account screen
        '/add-trip': (context) => const AddTripScreen(),
        '/earning': (context) => const EarningsScreen(),
        '/signin': (context) => const LoginsScreen(),
        '/passenger_home': (context) => const MainHomeScreen(),
        '/booking': (context) => const BookingScreen(),
        '/profile': (context) => const PassengerProfileScreen(),
        '/payment': (context) => const HomePaymentScreenTwo(),
        '/drivers_notification': (context) => const DriverNotificationScreen(),
        
        
        '/notification': (context) {
  return const NotificationsScreen(); // No longer passing passengerId
}


        // '/passenger_account': (context) => PassengerAccountScreen() 
      },
    );
  }
}
