import 'package:flutter/material.dart';

class page_utilisateur extends StatelessWidget {
  const page_utilisateur({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("LAMESIN")),
      backgroundColor: Color(0xFFE1F0FF),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color.fromARGB(255, 59, 98, 137),
          ),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {},
                child: Text("hopitaux pharmacies les plus proches"),
              ),
              SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {
                  print("");
                },
                icon: Icon(Icons.chat_bubble),
                label: Text("chatbot"),
              ),
              SizedBox(height: 15),
              ElevatedButton(onPressed: () {}, child: Text("rendez vous")),
            ],
          ),
        ),
      ),
    );
  }
}
