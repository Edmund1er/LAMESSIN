import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFFE1F5FE),
        body: Center(child: Image.asset("assets/images/accueil_image.jpeg")),
      ),
    );
  }
}
