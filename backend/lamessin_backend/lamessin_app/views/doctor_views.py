from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
# Statistiques par mois
from django.db.models import Count
from django.db.models.functions import TruncMonth

from lamessin_app.models import *
from lamessin_app.serializers import *


# ==================== 1. TABLEAU DE BORD MÉDECIN ====================

class DashboardMedecinView(APIView):
#Statistiques et résumé pour le tableau de bord médecin
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)

        aujourdhui = timezone.now().date()

# Rendez-vous du jour
        rdv_aujourdhui = RendezVous.objects.filter(
            medecin_concerne=medecin,
            date_rdv=aujourdhui
        ).exclude(statut_actuel_rdv='annulé')

# Rendez-vous à venir
        rdv_a_venir = RendezVous.objects.filter(
            medecin_concerne=medecin,
            date_rdv__gt=aujourdhui
        ).exclude(statut_actuel_rdv='annulé')

# Consultations totales
        consultations_total = Consultation.objects.filter(
            rdv__medecin_concerne=medecin
        ).count()

# Patients distincts
        patients_uniques = RendezVous.objects.filter(
            medecin_concerne=medecin
        ).values('patient_demandeur').distinct().count()

# Prochains rendez-vous (5 prochains)
        prochains_rdv = RendezVous.objects.filter(
            medecin_concerne=medecin,
            date_rdv__gte=aujourdhui
        ).exclude(statut_actuel_rdv='annulé').order_by('date_rdv', 'heure_rdv')[:5]

        return Response({
            'rdv_aujourdhui': rdv_aujourdhui.count(),
            'rdv_a_venir': rdv_a_venir.count(),
            'consultations_total': consultations_total,
            'patients_uniques': patients_uniques,
            'prochains_rdv': RendezVousSerializer(prochains_rdv, many=True).data,
        })


# ==================== 2. GESTION DES RENDEZ-VOUS ====================

class MedecinRendezVousView(APIView):
#Liste des rendez-vous du médecin avec filtres
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)

        filtre = request.query_params.get('filtre', 'tous')  # tous, aujourdhui, a_venir, passe
        aujourdhui = timezone.now().date()

        queryset = RendezVous.objects.filter(medecin_concerne=medecin)

        if filtre == 'aujourdhui':
            queryset = queryset.filter(date_rdv=aujourdhui)
        elif filtre == 'a_venir':
            queryset = queryset.filter(date_rdv__gt=aujourdhui)
        elif filtre == 'passe':
            queryset = queryset.filter(date_rdv__lt=aujourdhui)

        queryset = queryset.order_by('-date_rdv', '-heure_rdv')

        return Response(RendezVousSerializer(queryset, many=True).data)


class UpdateRendezVousStatutView(APIView):
#Modifier le statut d'un rendez-vous
    permission_classes = [IsAuthenticated]

    def patch(self, request, rdv_id):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
            rdv = get_object_or_404(RendezVous, id=rdv_id, medecin_concerne=medecin)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)

        nouveau_statut = request.data.get('statut')
        if nouveau_statut not in ['en_attente', 'confirme', 'annule', 'termine']:
            return Response({"error": "Statut invalide"}, status=400)

        rdv.statut_actuel_rdv = nouveau_statut
        rdv.save()

        return Response({
            'success': True,
            'message': f'Rendez-vous {nouveau_statut}',
            'statut': rdv.statut_actuel_rdv
        })


# ==================== 3. GESTION DES CONSULTATIONS ====================

class CreerConsultationView(APIView):
#Créer une consultation après un rendez-vous
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)

        rdv_id = request.data.get('rdv_id')
        if not rdv_id:
            return Response({"error": "ID du rendez-vous requis"}, status=400)

        rdv = get_object_or_404(RendezVous, id=rdv_id, medecin_concerne=medecin)

# Vérifier si une consultation existe déjà
        if hasattr(rdv, 'consultation'):
            return Response({"error": "Une consultation existe déjà pour ce rendez-vous"}, status=400)

        data = {
            'rdv': rdv.id,
            'diagnostic': request.data.get('diagnostic', ''),
            'actes_effectues': request.data.get('actes_effectues', ''),
            'notes_medecin': request.data.get('notes_medecin', ''),
        }

        serializer = ConsultationSerializer(data=data)
        if serializer.is_valid():
            consultation = serializer.save()
# Mettre à jour le statut du rendez-vous
            rdv.statut_actuel_rdv = 'termine'
            rdv.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=400)


class GetConsultationView(APIView):
#Détail d'une consultation
    permission_classes = [IsAuthenticated]

    def get(self, request, consultation_id):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
            consultation = get_object_or_404(
                Consultation,
                id=consultation_id,
                rdv__medecin_concerne=medecin
            )
            return Response(ConsultationSerializer(consultation).data)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)


# ==================== 4. GESTION DES ORDONNANCES ====================

class CreerOrdonnanceView(APIView):
#Prescrire une ordonnance
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)

        consultation_id = request.data.get('consultation_id')
        patient_id = request.data.get('patient_id')

        if not consultation_id or not patient_id:
            return Response({"error": "Consultation et patient requis"}, status=400)

        consultation = get_object_or_404(Consultation, id=consultation_id, rdv__medecin_concerne=medecin)
        patient = get_object_or_404(Patient, id=patient_id)

# Générer un code de sécurité unique
        import random
        import string
        code_securite = ''.join(random.choices(string.digits, k=10))

        ordonnance_data = {
            'consultation': consultation.id,
            'medecin_prescripteur': medecin.id,
            'patient_beneficiaire': patient.id,
            'code_securite': code_securite,
        }

        serializer = OrdonnanceSerializer(data=ordonnance_data)
        if serializer.is_valid():
            ordonnance = serializer.save()

# Ajouter les détails (médicaments)
            details = request.data.get('details', [])
            for detail in details:
                DetailOrdonnance.objects.create(
                    ordonnance=ordonnance,
                    medicament_id=detail.get('medicament_id'),
                    quantite_boites=detail.get('quantite_boites', 1),
                    posologie_specifique=detail.get('posologie', ''),
                    duree_traitement_jours=detail.get('duree_traitement', 0)
                )

            return Response(OrdonnanceSerializer(ordonnance).data, status=201)

        return Response(serializer.errors, status=400)


class OrdonnancesMedecinView(APIView):
#Liste des ordonnances prescrites par le médecin
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
            ordonnances = Ordonnance.objects.filter(medecin_prescripteur=medecin).order_by('-date_prescription')
            return Response(OrdonnanceSerializer(ordonnances, many=True).data)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)


# ==================== 5. GESTION DES DISPONIBILITÉS ====================

class GererPlagesHorairesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
            plages = PlageHoraire.objects.filter(medecin=medecin).order_by('-date', 'heure_debut')
            return Response(PlageHoraireSerializer(plages, many=True).data)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)

    def post(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)

        data = request.data.copy()
        data['medecin'] = medecin.pk  # 
        serializer = PlageHoraireSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

    def delete(self, request, plage_id):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
            plage = get_object_or_404(PlageHoraire, id=plage_id, medecin=medecin)
            plage.delete()
            return Response({"success": True, "message": "Plage horaire supprimée"})
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)


# ==================== 6. GESTION DES PATIENTS ====================

class ListePatientsMedecinView(APIView):
#Liste des patients du médecin
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
# Récupérer les patients uniques qui ont eu un RDV avec ce médecin
            patients_ids = RendezVous.objects.filter(
                medecin_concerne=medecin
            ).values_list('patient_demandeur', flat=True).distinct()

            patients = Patient.objects.filter(id__in=patients_ids)
            return Response(PatientSerializer(patients, many=True).data)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)


class DossierPatientView(APIView):
#Consulter le dossier médical complet d'un patient
    permission_classes = [IsAuthenticated]

    def get(self, request, patient_id):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
            patient = get_object_or_404(Patient, id=patient_id)

# Vérifier que le patient a eu un RDV avec ce médecin
            rdv_existe = RendezVous.objects.filter(
                medecin_concerne=medecin,
                patient_demandeur=patient
            ).exists()

            if not rdv_existe:
                return Response({"error": "Non autorisé"}, status=403)

# Récupérer toutes les données du patient
            consultations = Consultation.objects.filter(rdv__patient_demandeur=patient)
            ordonnances = Ordonnance.objects.filter(patient_beneficiaire=patient)
            traitements = Traitement.objects.filter(patient_concerne=patient)

            return Response({
                'patient': PatientSerializer(patient).data,
                'consultations': ConsultationSerializer(consultations, many=True).data,
                'ordonnances': OrdonnanceSerializer(ordonnances, many=True).data,
                'traitements': TraitementSerializer(traitements, many=True).data,
            })
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)


# ==================== 7. STATISTIQUES ====================

class StatistiquesMedecinView(APIView):
#Statistiques détaillées du médecin
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)


        consultations_par_mois = Consultation.objects.filter(
            rdv__medecin_concerne=medecin
        ).annotate(
            mois=TruncMonth('date_consultation')
        ).values('mois').annotate(
            count=Count('id')
        ).order_by('-mois')[:12]

        # Top médicaments prescrits
        top_medicaments = DetailOrdonnance.objects.filter(
            ordonnance__medecin_prescripteur=medecin
        ).values(
            'medicament__nom_commercial'
        ).annotate(
            total_quantite=Count('quantite_boites')
        ).order_by('-total_quantite')[:10]

        return Response({
            'consultations_par_mois': list(consultations_par_mois),
            'top_medicaments': list(top_medicaments),
        })

class UploadDocumentMedicalView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            medecin = Medecin.objects.get(compte_utilisateur=request.user)
        except Medecin.DoesNotExist:
            return Response({"error": "Médecin non trouvé"}, status=404)

        consultation_id = request.data.get('consultation_id')
        if not consultation_id:
            return Response({"error": "ID de consultation requis"}, status=400)

        consultation = get_object_or_404(
            Consultation,
            id=consultation_id,
            rdv__medecin_concerne=medecin
        )

        fichier = request.FILES.get('document')
        if not fichier:
            return Response({"error": "Aucun document fourni"}, status=400)

        # Sauvegarder le document
        consultation.document_joint = fichier
        consultation.save()

        return Response({
            'success': True,
            'message': 'Document uploadé avec succès',
            'document_url': consultation.document_joint.url if consultation.document_joint else None
        }, status=200)