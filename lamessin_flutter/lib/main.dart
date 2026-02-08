import 'package:flutter/material.dart';
import 'PAGES_/login.dart';
import 'PAGES_/register.dart';
import 'PAGES_/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      initialRoute: "/login", 
      
      routes: {
        "/login": (context) => const Login(),
        
        "/register": (context) => const Register(),
        
        "/home_page": (context) => const HomePage(), 
      },
    );
  }
}