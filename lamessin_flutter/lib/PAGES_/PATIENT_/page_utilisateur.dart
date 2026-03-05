import 'package:flutter/material.dart';

class page_utilisateur extends StatelessWidget {
  const page_utilisateur({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LAMESIN"), centerTitle: true),
      backgroundColor: const Color(0xFFE1F0FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 90,
              child: Card(
                color: const Color(0xFF0056b3),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/recherches_services_medicaux',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: const [
                        Icon(Icons.local_hospital, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Hôpitaux et pharmacies les plus proches",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 90,
              width: MediaQuery.of(context).size.width * 0.85,
              child: Card(
                color: const Color(0xFF0056b3),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/rendez_vous_page');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: const [
                        Icon(Icons.calendar_month, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "rendez vous",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 90,
              width: MediaQuery.of(context).size.width * 0.85,
              child: Card(
                color: const Color(0xFF0056b3),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/assistant');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: const [
                        Icon(Icons.chat_bubble, color: Colors.white),
                        SizedBox(width: 10),
                        Text("chatbot", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
