import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Services extends StatefulWidget {
  const Services({super.key});

  @override
  State<Services> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Services> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SERVICES")),
      body: SizedBox(child: Card()),
    );
  }
}
