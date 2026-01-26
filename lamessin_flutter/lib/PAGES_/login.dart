import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.blue,
        appBar: AppBar(
          title: const Text("BIENVENUE SUR LA PAGE LAMESSIN"),
          centerTitle: true, // <-- centre le titre
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("", style: TextStyle(fontSize: 30)),
              Text(""),
            ],
          ),
        ),
      ),
    );
  }
}
