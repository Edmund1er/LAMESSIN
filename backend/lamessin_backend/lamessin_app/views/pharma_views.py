from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.db.models import Sum, Count, F
from django.db.models.functions import TruncMonth
from django.shortcuts import get_object_or_404
from django.utils import timezone

from lamessin_app.models import (
    Pharmacien, Pharmacie, Medicament, Stock, Commande, LigneCommande,
    Ordonnance, DetailOrdonnance, Patient, EtablissementSante
)

from lamessin_app.serializers import (
    PharmacienSerializer, MedicamentSerializer, StockSerializer,
    CommandeSerializer, LigneCommandeSerializer, OrdonnanceSerializer,
    PatientSerializer
)


# ==================== 1. TABLEAU DE BORD PHARMACIEN ====================

class DashboardPharmacienView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée à ce compte"}, status=404)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        stocks = Stock.objects.filter(pharmacie_detentrice=pharmacie)
        total_produits = stocks.count()
        produits_en_rupture = stocks.filter(quantite_actuelle_en_stock=0).count()
        produits_alerte = stocks.filter(quantite_actuelle_en_stock__lte=F('seuil_alerte')).count()

        commandes_attente = Commande.objects.filter(
            lignes__pharmacie=pharmacie,
            statut='EN_ATTENTE'
        ).distinct().count()

        commandes_total = Commande.objects.filter(
            lignes__pharmacie=pharmacie
        ).distinct().count()

        commandes_payees = Commande.objects.filter(
            lignes__pharmacie=pharmacie,
            statut='PAYE'
        ).distinct()

        ca_total = sum(float(c.total) for c in commandes_payees)

        commandes_recentes = Commande.objects.filter(
            lignes__pharmacie=pharmacie
        ).distinct().order_by('-date_creation')[:5]

        return Response({
            'total_produits': total_produits,
            'produits_en_rupture': produits_en_rupture,
            'produits_alerte': produits_alerte,
            'commandes_attente': commandes_attente,
            'commandes_total': commandes_total,
            'ca_total': ca_total,
            'commandes_recentes': CommandeSerializer(commandes_recentes, many=True).data,
        })


# ==================== 2. GESTION DES STOCKS ====================

class GererStockView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
            stocks = Stock.objects.filter(pharmacie_detentrice=pharmacie)
            serializer = StockSerializer(stocks, many=True)
            return Response(serializer.data)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

    def post(self, request):
        """Ajouter ou mettre à jour un stock pour un médicament existant"""
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        medicament_id = request.data.get('medicament_id')
        quantite = request.data.get('quantite', 0)
        seuil_alerte = request.data.get('seuil_alerte', 10)
        date_peremption = request.data.get('date_peremption')

        if not medicament_id:
            return Response({"error": "ID du médicament requis"}, status=400)

        try:
            medicament = Medicament.objects.get(id=medicament_id)
        except Medicament.DoesNotExist:
            return Response({"error": "Médicament non trouvé"}, status=404)

        # Éviter les doublons: get_or_create
        stock, created = Stock.objects.get_or_create(
            produit_concerne=medicament,
            pharmacie_detentrice=pharmacie,
            defaults={
                'quantite_actuelle_en_stock': quantite,
                'seuil_alerte': seuil_alerte,
                'date_peremption': date_peremption or '2025-12-31'
            }
        )

        if not created:
            stock.quantite_actuelle_en_stock = quantite
            stock.seuil_alerte = seuil_alerte
            if date_peremption:
                stock.date_peremption = date_peremption
            stock.save()

        return Response(StockSerializer(stock).data, status=status.HTTP_201_CREATED)


class UpdateStockView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, stock_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
            stock = get_object_or_404(Stock, id=stock_id, pharmacie_detentrice=pharmacie)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        quantite = request.data.get('quantite')
        if quantite is not None:
            stock.quantite_actuelle_en_stock = quantite
            stock.save()

        return Response(StockSerializer(stock).data)


class AlertesStockView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
            alertes = Stock.objects.filter(
                pharmacie_detentrice=pharmacie,
                quantite_actuelle_en_stock__lte=F('seuil_alerte')
            )
            return Response(StockSerializer(alertes, many=True).data)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)


# ==================== 3. GESTION DES COMMANDES ====================

class CommandesPharmacieView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        filtre = request.query_params.get('filtre', 'toutes')
        queryset = Commande.objects.filter(lignes__pharmacie=pharmacie).distinct()

        if filtre == 'en_attente':
            queryset = queryset.filter(statut='EN_ATTENTE')
        elif filtre == 'payees':
            queryset = queryset.filter(statut='PAYE')

        queryset = queryset.order_by('-date_creation')
        return Response(CommandeSerializer(queryset, many=True).data)


class DetailCommandePharmacieView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, commande_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
            commande = get_object_or_404(
                Commande,
                id=commande_id,
                lignes__pharmacie=pharmacie
            )
            return Response(CommandeSerializer(commande).data)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)


class ValiderCommandeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, commande_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
            commande = get_object_or_404(
                Commande,
                id=commande_id,
                lignes__pharmacie=pharmacie
            )
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        if commande.statut != 'PAYE':
            return Response({"error": "La commande n'est pas encore payée"}, status=400)

        with transaction.atomic():
            lignes = LigneCommande.objects.filter(commande=commande, pharmacie=pharmacie)
            for ligne in lignes:
                stock = Stock.objects.get(
                    produit_concerne=ligne.produit,
                    pharmacie_detentrice=pharmacie
                )
                stock.quantite_actuelle_en_stock -= ligne.quantite
                stock.save()
            commande.statut = 'LIVRE'
            commande.save()

        return Response({"success": True, "message": "Commande validée et prête pour retrait"})


class MarquerCommandeLivreeView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, commande_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            commande = get_object_or_404(Commande, id=commande_id)
            lignes = commande.lignes.filter(pharmacie=pharmacien.pharmacie)
            if not lignes.exists():
                return Response({"error": "Non autorisé"}, status=403)
            commande.statut = 'LIVRE'
            commande.save()
            return Response({"success": True, "message": "Commande marquée comme livrée"})
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)


# ==================== 4. GESTION DES MÉDICAMENTS ====================

class CatalogueMedicamentsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        medicaments = Medicament.objects.all().order_by('nom_commercial')
        return Response(MedicamentSerializer(medicaments, many=True).data)


class GererMedicamentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Ajouter un nouveau médicament et créer son stock automatiquement"""
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        nom = request.data.get('nom')
        description = request.data.get('description', '')
        posologie = request.data.get('posologie', '')
        prix = request.data.get('prix', 0)
        quantite_initiale = request.data.get('quantite_initiale', 0)
        seuil_alerte = request.data.get('seuil_alerte', 10)
        date_peremption = request.data.get('date_peremption', '2025-12-31')

        if not nom or not prix:
            return Response({"error": "Nom et prix requis"}, status=400)

        with transaction.atomic():
            # Créer le médicament
            medicament = Medicament.objects.create(
                nom_commercial=nom,
                description=description,
                posologie_standard=posologie,
                prix_vente=prix
            )

            # Créer automatiquement le stock associé
            Stock.objects.create(
                produit_concerne=medicament,
                pharmacie_detentrice=pharmacie,
                quantite_actuelle_en_stock=quantite_initiale,
                seuil_alerte=seuil_alerte,
                date_peremption=date_peremption
            )

        return Response(MedicamentSerializer(medicament).data, status=status.HTTP_201_CREATED)

    def put(self, request, medicament_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            medicament = get_object_or_404(Medicament, id=medicament_id)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        serializer = MedicamentSerializer(medicament, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)


# ==================== 5. SCAN ORDONNANCE ====================

class ScannerOrdonnanceView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, code_securite):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            ordonnance = get_object_or_404(Ordonnance, code_securite=code_securite)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        return Response({
            'valide': True,
            'ordonnance': OrdonnanceSerializer(ordonnance).data,
            'patient': PatientSerializer(ordonnance.patient_beneficiaire).data,
        })


class ValiderOrdonnanceView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, ordonnance_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
            ordonnance = get_object_or_404(Ordonnance, id=ordonnance_id)
        except (Pharmacien.DoesNotExist, AttributeError):
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        details = DetailOrdonnance.objects.filter(ordonnance=ordonnance)
        stock_manquant = []

        for detail in details:
            stock = Stock.objects.filter(
                produit_concerne=detail.medicament,
                pharmacie_detentrice=pharmacie
            ).first()

            if not stock or stock.quantite_actuelle_en_stock < detail.quantite_boites:
                stock_manquant.append({
                    'medicament': detail.medicament.nom_commercial,
                    'disponible': stock.quantite_actuelle_en_stock if stock else 0,
                    'requis': detail.quantite_boites
                })

        if stock_manquant:
            return Response({
                'success': False,
                'stock_manquant': stock_manquant,
                'message': 'Certains médicaments ne sont pas en stock'
            }, status=400)

        with transaction.atomic():
            commande = Commande.objects.create(
                patient=ordonnance.patient_beneficiaire,
                total=0,
                statut='PAYE',
                methode_retrait='RETRAIT'
            )

            total_commande = 0
            for detail in details:
                prix = float(detail.medicament.prix_vente)
                LigneCommande.objects.create(
                    commande=commande,
                    produit=detail.medicament,
                    pharmacie=pharmacie,
                    quantite=detail.quantite_boites,
                    prix_unitaire=prix
                )
                total_commande += prix * detail.quantite_boites

                stock = Stock.objects.get(
                    produit_concerne=detail.medicament,
                    pharmacie_detentrice=pharmacie
                )
                stock.quantite_actuelle_en_stock -= detail.quantite_boites
                stock.save()

            commande.total = total_commande
            commande.save()

        return Response({
            'success': True,
            'commande_id': commande.id,
            'message': 'Ordonnance validée, médicaments préparés'
        })


# ==================== 6. STATISTIQUES PHARMACIE ====================

class StatistiquesPharmacieView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
        except (Pharmacien.DoesNotExist, AttributeError):
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        ventes_par_mois = LigneCommande.objects.filter(
            pharmacie=pharmacie,
            commande__statut='PAYE'
        ).annotate(
            mois=TruncMonth('commande__date_creation')
        ).values('mois').annotate(
            total_ventes=Sum('quantite'),
            ca=Sum('prix_unitaire')
        ).order_by('-mois')[:12]

        top_medicaments = LigneCommande.objects.filter(
            pharmacie=pharmacie,
            commande__statut='PAYE'
        ).values(
            'produit__nom_commercial'
        ).annotate(
            total_vendus=Sum('quantite'),
            ca_total=Sum('prix_unitaire')
        ).order_by('-total_vendus')[:10]

        return Response({
            'ventes_par_mois': list(ventes_par_mois),
            'top_medicaments': list(top_medicaments),
        })

class SupprimerStockView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, stock_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = pharmacien.pharmacie
            if not pharmacie:
                return Response({"error": "Aucune pharmacie associée"}, status=404)
            stock = get_object_or_404(Stock, id=stock_id, pharmacie_detentrice=pharmacie)
            stock.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

