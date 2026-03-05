import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class Assistant extends StatefulWidget {
  const Assistant({super.key});

  @override
  State<Assistant> createState() => _AssistantState();
}

class _AssistantState extends State<Assistant> {
  final controler = TextEditingController();
  String reponse = "poser votre question";
  final model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: "AIzaSyDhRNdBQYzqrXmN1dtp01iCQpzZamEWu9g",
  );
  void envoyer() async {
    final prompt = [Content.text(controler.text)];
    final response = await model.generateContent(prompt);

    setState(() {
      reponse = response.text ?? "Erreur de réponse";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Assistant")),
      body: Padding(
        padding: EdgeInsets.all(8.5),
        child: Column(
          children: [
            Expanded(child: SingleChildScrollView(child: Text(reponse))),
            TextField(
              controller: controler,
              decoration: InputDecoration(hintText: "votre question"),
            ),
            ElevatedButton(onPressed: envoyer, child: Text("envoyer")),
          ],
        ),
      ),
    );
  }
}
