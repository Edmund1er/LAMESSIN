# lamessin_app/views/patient_views.py

import os
import json
import requests
from datetime import datetime, timedelta
from django.db import transaction
from django.utils.dateparse import parse_date
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.tokens import RefreshToken

import google.generativeai as genai

from firebase_admin import messaging
from collections import defaultdict

from lamessin_app.models import *
from lamessin_app.serializers import *
from lamessin_app.services.paygate_service import PayGateService


# ====================================================================================================
# CONFIGURATION
# ====================================================================================================

MY_DOMAIN = os.environ.get("MY_DOMAIN", "http://localhost:8000")


# ====================================================================================================
# FONCTION UTILITAIRE : NOTIFICATIONS PUSH
# ====================================================================================================

def notifier_paiement_reussi(utilisateur, commande_id):
    if not utilisateur.fcm_token:
        return

    message = messaging.Message(
        notification=messaging.Notification(
            title="Paiement validé",
            body=f"Votre commande n°{commande_id} est confirmée. La pharmacie a été créditée.",
        ),
        data={
            "type": "PAIEMENT_VALIDE",
            "commande_id": str(commande_id),
        },
        token=utilisateur.fcm_token,
    )

    try:
        messaging.send(message)
    except Exception as e:
        print(f"Erreur FCM: {e}")


# ====================================================================================================
# RECHERCHE & ÉTABLISSEMENTS
# ====================================================================================================

class RechercheMedicament(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        query = request.query_params.get('q', '')
        medicaments = Medicament.objects.filter(
            nom_commercial__istartswith=query) if query else Medicament.objects.all()[:50]
        serializer = MedicamentsSerializer(medicaments, many=True)
        return Response(serializer.data)


class ListeEtablissements(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        type_filtre = request.query_params.get('type')

        if type_filtre == 'pharmacie':
            etablissements = Pharmacie.objects.all()
        elif type_filtre == 'hopital':
            etablissements = Hopital.objects.all()
        else:
            etablissements = EtablissementSante.objects.all()

        return Response(EtablissementSanteSerializer(etablissements, many=True).data)


# ====================================================================================================
# RENDEZ-VOUS
# ====================================================================================================

class LiteMedecins(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        medecins = Medecin.objects.all()
        return Response(MedecinSerializer(medecins, many=True).data)


class CreezRendezVous(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
        except Patient.DoesNotExist:
            return Response({"error": "Seuls les patients peuvent prendre RDV"}, status=403)
        
        data = request.data.copy()
        data['patient_demandeur'] = patient.pk
        serializer = RendezVousCreateSerializer(data=data)
        
        if serializer.is_valid():
            rdv = serializer.save()

            # Notification pour le patient
            Notification.objects.create(
                destinataire=request.user,
                message=f"Rendez-vous enregistré avec le Dr {rdv.medecin_concerne.compte_utilisateur.last_name} pour le {rdv.date_rdv}.",
                type_notification="RENDEZ_VOUS_CREE"
            )

            # Notification pour le médecin
            Notification.objects.create(
                destinataire=rdv.medecin_concerne.compte_utilisateur,
                message=f"Nouveau rendez-vous avec {patient.compte_utilisateur.first_name} {patient.compte_utilisateur.last_name} pour le {rdv.date_rdv} à {rdv.heure_rdv}.",
                type_notification="RENDEZ_VOUS_CREE"
            )

            return Response({"success": True, "message": "RDV enregistré"}, status=201)
        
        return Response(serializer.errors, status=400)


class CreneauxDispo(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        medecin_id = request.query_params.get('medecin')
        date_str = request.query_params.get('date')
        if not medecin_id or not date_str:
            return Response({"error": "Paramètres requis."}, status=400)
        date_obj = parse_date(date_str)
        maintenant = timezone.localtime(timezone.now())
        plages = PlageHoraire.objects.filter(medecin_id=medecin_id, date=date_obj)
        rdvs_existants = RendezVous.objects.filter(
            medecin_concerne_id=medecin_id, date_rdv=date_obj
        ).exclude(statut_actuel_rdv="annulé").values_list('heure_rdv', flat=True)

        creneaux = []
        for plage in plages:
            t = datetime.combine(plage.date, plage.heure_debut)
            fin = datetime.combine(plage.date, plage.heure_fin)
            pas = timedelta(minutes=plage.duree_consultation)
            while t + pas <= fin:
                h = t.time()
                if h not in rdvs_existants and not (date_obj == maintenant.date() and h <= maintenant.time()):
                    fmt = h.strftime('%H:%M')
                    creneaux.append({"id": fmt, "heure": fmt})
                t += pas
        return Response(creneaux)


class ListeRendezVousPatient(generics.ListAPIView):
    serializer_class = RendezVousSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return RendezVous.objects.filter(
            patient_demandeur__compte_utilisateur=self.request.user
        ).order_by('date_rdv', 'heure_rdv')


class AnnulerRendezVous(generics.UpdateAPIView):
    queryset = RendezVous.objects.all()
    serializer_class = RendezVousSerializer
    permission_classes = [IsAuthenticated]

    def patch(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.patient_demandeur.compte_utilisateur != request.user:
            return Response({"error": "Action non autorisée"}, status=403)
        instance.statut_actuel_rdv = "annulé"
        instance.save()
        return Response({"success": True, "message": "Rendez-vous annulé."})


# ====================================================================================================
# COMMANDES & PAIEMENTS (PAYGATE)
# ====================================================================================================

class MesCommandesView(generics.ListAPIView):
    serializer_class = CommandeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Commande.objects.filter(
            patient__compte_utilisateur=self.request.user
        ).order_by('-date_creation')


class CreerCommandeMultiple(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        articles = request.data.get('articles', [])

        print(f"ARTICLES RECUS: {articles}")

        if not articles:
            return Response({"error": "Panier vide"}, status=400)

        try:
            with transaction.atomic():
                patient = Patient.objects.get(compte_utilisateur=request.user)

                commande = Commande.objects.create(
                    patient=patient,
                    total=0,
                    statut='EN_ATTENTE',
                )

                total_general = 0

                for item in articles:
                    medoc_id = item.get('id')
                    pharmacie_id = item.get('pharmacie_id')
                    qte = item.get('qte', 1)

                    print(f"Item: medoc_id={medoc_id}, pharmacie_id={pharmacie_id}, qte={qte}")

                    if not medoc_id or not pharmacie_id:
                        return Response({
                            "error": f"Données invalides: {item}"
                        }, status=400)

                    medoc = get_object_or_404(Medicament, id=medoc_id)
                    pharmacie = get_object_or_404(Pharmacie, id=pharmacie_id)
                    pv = float(medoc.prix_vente)

                    LigneCommande.objects.create(
                        commande=commande,
                        produit=medoc,
                        pharmacie=pharmacie,
                        quantite=qte,
                        prix_unitaire=pv
                    )
                    total_general += (pv * qte)

                commande.total = total_general
                commande.save()

                # Notification patient
                Notification.objects.create(
                    destinataire=request.user,
                    message=f"Votre commande #{commande.id} a été enregistrée avec succès. Montant: {total_general} FCFA",
                    type_notification="COMMANDE_CREE"
                )

                return Response({
                    'success': True,
                    'commande_id': commande.id,
                    'total': total_general,
                    'message': 'Commande créée avec succès'
                }, status=201)

        except Exception as e:
            print(f"ERREUR: {str(e)}")
            return Response({'error': str(e)}, status=400)


class InitierPaiementMobileMoney(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
        except Patient.DoesNotExist:
            return Response({"error": "Patient non trouvé"}, status=404)

        commande_id = request.data.get('commande_id')
        telephone = request.data.get('telephone')
        operateur = request.data.get('operateur')

        print(f"DEBUG: commande_id={commande_id}, telephone={telephone}, operateur={operateur}")

        if not commande_id or not telephone or not operateur:
            return Response({
                "error": "Paramètres requis: commande_id, telephone, operateur"
            }, status=400)

        commande = get_object_or_404(Commande, id=commande_id, patient=patient)

        if commande.statut == 'PAYE':
            return Response({"error": "Commande déjà payée"}, status=400)

        identifier = f"LAMESSIN_{commande.id}_{int(timezone.now().timestamp())}"

        resultat = PayGateService.initier_paiement(
            montant=float(commande.total),
            telephone=telephone,
            operateur=operateur,
            identifier=identifier
        )

        if resultat.get('success'):
            commande.transaction_id = resultat['tx_reference']
            commande.save()

            return Response({
                'success': True,
                'tx_reference': resultat['tx_reference'],
                'identifier': identifier,
                'message': 'Vérifiez votre téléphone et confirmez le paiement'
            })
        else:
            return Response({
                'success': False,
                'error': resultat.get('error', 'Erreur de paiement')
            }, status=400)


class VerifierStatutPaiement(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, commande_id):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
            commande = get_object_or_404(Commande, id=commande_id, patient=patient)
        except Patient.DoesNotExist:
            return Response({"error": "Patient non trouvé"}, status=404)

        if not commande.transaction_id:
            return Response({
                'statut': 'INCONNU',
                'commande_statut': commande.statut
            })

        resultat = PayGateService.verifier_statut(commande.transaction_id)

        if resultat.get('status') == 'SUCCES' and commande.statut != 'PAYE':
            commande.statut = 'PAYE'
            commande.save()

            for ligne in commande.lignes.all():
                stock = Stock.objects.filter(
                    produit_concerne=ligne.produit,
                    pharmacie_detentrice=ligne.pharmacie
                ).first()
                if stock:
                    stock.quantite_actuelle_en_stock -= ligne.quantite
                    stock.save()

            notifier_paiement_reussi(commande.patient.compte_utilisateur, commande.id)

        return Response({
            'statut': resultat.get('status', 'INCONNU'),
            'commande_statut': commande.statut,
            'payment_method': resultat.get('payment_method')
        })


# ====================================================================================================
# TRAITEMENTS & DOSSIER PATIENT
# ====================================================================================================

class ListeTraitementsPatient(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            patient = Patient.objects.get(compte_utilisateur=request.user)
            traitements = Traitement.objects.filter(patient_concerne=patient)
            return Response(TraitementSerializer(traitements, many=True).data)
        except Patient.DoesNotExist:
            return Response({"error": "Profil patient non trouvé"}, status=404)


class DetailTraitement(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        traitement = get_object_or_404(Traitement, id=pk, patient_concerne__compte_utilisateur=request.user)
        prises = PriseMedicament.objects.filter(traitement=traitement).order_by('date_prise_reelle',
                                                                                'heure_prise_prevue')
        data = TraitementSerializer(traitement).data
        data['historique_prises'] = PriseMedicamentSerializer(prises, many=True).data
        return Response(data)


class ValiderPriseMedicament(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, prise_id):
        prise = get_object_or_404(PriseMedicament, id=prise_id,
                                  traitement__patient_concerne__compte_utilisateur=request.user)
        prise.prise_effectuee = True
        prise.date_prise_reelle = timezone.now().date()
        prise.save()
        return Response({"success": True, "message": "Prise enregistrée"})


class ListeOrdonnancesPatient(generics.ListAPIView):
    serializer_class = OrdonnanceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Ordonnance.objects.filter(
            patient_beneficiaire__compte_utilisateur=self.request.user
        ).order_by('-date_prescription')


# ====================================================================================================
# ASSISTANT CHATBOT GEMINI (PATIENT)
# ====================================================================================================

@api_view(["POST"])
@permission_classes([AllowAny])
def assistant(request):
    genai.configure(api_key=os.environ.get("GEMINI_KEY", "AIzaSyB_talvIiJ6Sent62bneLzx_QciGUW90zk"))
    model = genai.GenerativeModel("gemini-2.5-flash")
    response = model.generate_content(request.data.get("prompt", ""))
    return Response({"reponse": response.text})


class AssistantHistoriqueView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        session, _ = Chatbot.objects.get_or_create(utilisateur=request.user)
        messages = Message.objects.filter(chatbot_associe=session).order_by('heure_message')
        return Response(MessageSerializer(messages, many=True).data)