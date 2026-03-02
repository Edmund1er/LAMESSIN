import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class recherches_services_medicaux extends StatefulWidget {
  const recherches_services_medicaux({super.key});

  @override
  State<recherches_services_medicaux> createState() =>
      _RecherchesServicesMedicauxState();
}

class _RecherchesServicesMedicauxState
    extends State<recherches_services_medicaux> {
  String selectionservice = "pharmacie";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Services proches"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0056b3),
      ),
      backgroundColor: const Color(0xFFE1F0FF),
      body: Center(
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Color(0xFF0056b3),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Choisir un service",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                RadioListTile<String>(
                  value: "pharmacie",
                  title: const Text("Pharmacie"),
                  groupValue: selectionservice,
                  activeColor: const Color(0xFF0056b3),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectionservice = val;
                      });
                    }
                  },
                ),

                RadioListTile<String>(
                  value: "hopitaux",
                  title: const Text("Hôpitaux"),
                  groupValue: selectionservice,
                  activeColor: const Color(0xFF0056b3),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectionservice = val;
                      });
                    }
                  },
                ),
                RadioListTile<String>(
                  value: "cliniques",
                  title: const Text("cliniques"),
                  groupValue: selectionservice,
                  activeColor: const Color(0xFF0056b3),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectionservice = val;
                      });
                    }
                  },
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0056b3),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text(
                      "Rechercher",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      localisation localisationService = localisation();
                      Position? position = await localisationService
                          .position_client();

                      if (position != null) {
                        final Key = "";
                        String service = "pharmacie";
                        if (selectionservice == "pharmacie") {
                          service = "pharmacy";
                        } else if (selectionservice == "Hôpitaux") {
                          service = "hospital";
                        } else if (selectionservice == "cliniques") {
                          service = "health";
                        }
                        final url =
                            "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=5000&type=$service&key=$Key";
                        final res = await http.get(Uri.parse(url));
                        return json.decode(res.body)['results'];
                      }
                      Navigator.pushNamed(context, "/services");
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class localisation {
  Future<bool> verifierpermision() async {
    bool serviceActif = await Geolocator.isLocationServiceEnabled();
    if (!serviceActif) return false;

    LocationPermission permissions = await Geolocator.checkPermission();
    if (permissions == LocationPermission.denied) {
      permissions = await Geolocator.requestPermission();
      if (permissions == LocationPermission.denied) return false;
    }
    return true;
  }

  Future<Position?> position_client() async {
    if (await verifierpermision()) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }
    return null;
  }
}
