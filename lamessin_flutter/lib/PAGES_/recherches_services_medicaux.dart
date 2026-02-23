import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class recherches_services_medicaux extends StatefulWidget {
  const recherches_services_medicaux({super.key});

  @override
  State<recherches_services_medicaux> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<recherches_services_medicaux> {
  @override
  Widget build(BuildContext context) {
    String selectionservice = "pharmacie";
    return Row(
      children: [
        RadioListTile<String>(
          value: "pharmacie",
          title: Text("pharmacie"),
          groupValue: selectionservice,
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
          title: Text("hopitaux"),
          groupValue: selectionservice,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                selectionservice = val;
              });
            }
          },
        ),
        ElevatedButton(
          onPressed: () async {
            localisation localisationService = localisation();
            Position? position = await localisationService.position_client();

            if (position != null) {
              double latitude = position.latitude;
              double longitude = position.longitude;

              print(latitude);
              print(longitude);
            }
          },
          child: Text("Rechercher"),
        ),
      ],
    );
  }
}

class localisation {
  Future<bool> verifierpermision() async {
    bool permission = await Geolocator.isLocationServiceEnabled();
    if (!permission) return false;
    LocationPermission permissions = await Geolocator.checkPermission();
    if (permissions == LocationPermission.denied) {
      permissions = await Geolocator.requestPermission();
      if (permissions == LocationPermission.denied) return false;
    }
    return true;
  }

  Future<Position?> position_client() async {
    if (await verifierpermision()) {
      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }
    Position? positionclient = await localisation().position_client();
  }
}
