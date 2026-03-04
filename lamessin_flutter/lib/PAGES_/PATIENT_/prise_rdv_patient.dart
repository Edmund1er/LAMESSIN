import 'package:flutter/material.dart';
// Pour transformer les dates en texte


//creeons le widget state ful

class RendezVousPage extends StatefulWidget
  {
    const RendezVousPage({super.key});

    @override
    State<RendezVousPage> createState() => _RendezVousPageState();
  }

// pour le stockage des variables pour garder les informations que l'utilisateur va entrée ou saisir

class _RendezVousPageState extends State<RendezVousPage>
  {

    int? _idMedecinSelectionne;

    int? _idCreneauSelectionne;

//ici j'ai mis ? pour dire que la variable priver _dateChoise peut etre null 

    DateTime ? _dateChoisie  ; 

//maint pour stocké le motif du rdv le controlleur va premttre de savoir ce que l'utilisateur saisie
    final _motif = TextEditingController();

    void _validerRendezVous()
      {
//on vérifie la date
        if (_dateChoisie == null) 
          {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Veuillez choisir une date"), backgroundColor: Colors.orange),);
            return;
          }

//Ensuite on vérifie le motif
        if (_motif.text.isEmpty) 
          {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Veuillez préciser le motif de la visite."), backgroundColor: Colors.orange),);
            return; 
          }
//ce qui sera envoyer a django

        Map<String , dynamic> rdv = {
          "patient_demandeur": 1,
          "medecin_concerne": _idMedecinSelectionne,
          "creneau_reserve" : _idCreneauSelectionne,
          "motif_consultation": _motif.text,
          "statut_actuel_rdv":"en_attente",
          
        };

        print("l'envoie à django : $rdv");
      }






//'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''



    @override
    Widget build(BuildContext context)
      {
        return Scaffold(
          appBar: AppBar(title: Text("Prendre Rendez-vous")),
          body: Column(
            children: [
// utilisont ! au niveau du tostring pour eviter "possible null error"
            ListTile(title: Text(_dateChoisie==null ? "choisir une date" : _dateChoisie!.toString()),
            trailing:Icon(Icons.calendar_today),
            onTap:()async
              {
                DateTime? calendrier = await showDatePicker(context: context,
                initialDate : DateTime.now(),
                firstDate : DateTime.now(),
                lastDate : DateTime(2027),
                );

                if(calendrier!=null)
                  {
// pour que l'interface se reconstruise apres que il y'ai eu un changment
                    setState(()
                      {
                        _dateChoisie = calendrier;
                      }
                      );
                  }
              },
            ),
            ],
          ),
        );
      }
  }


  
