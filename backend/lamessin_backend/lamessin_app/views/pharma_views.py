
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone

from lamessin_app.models import (
    Pharmacien, Pharmacie, Medicament, Stock, Commande, LigneCommande,
    Ordonnance, DetailOrdonnance, Patient
)
from lamessin_app.serializers import (
    PharmacienSerializer, MedicamentSerializer, StockSerializer,
    CommandeSerializer, LigneCommandeSerializer, OrdonnanceSerializer,
    PatientSerializer
)


# ==================== 1. TABLEAU DE BORD PHARMACIEN ====================

class DashboardPharmacienView(APIView):
    """Statistiques pour le tableau de bord pharmacien"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)  # Pharmacien hérite de EtablissementSante
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Pharmacien ou pharmacie non trouvé"}, status=404)

        # Statistiques stock
        stocks = Stock.objects.filter(pharmacie_detentrice=pharmacie)
        total_produits = stocks.count()
        produits_en_rupture = stocks.filter(quantite_actuelle_en_stock=0).count()
        produits_alerte = stocks.filter(quantite_actuelle_en_stock__lte=models.F('seuil_alerte')).count()

        # Commandes
        commandes_attente = Commande.objects.filter(
            lignes__pharmacie=pharmacie,
            statut='EN_ATTENTE'
        ).distinct().count()

        commandes_total = Commande.objects.filter(
            lignes__pharmacie=pharmacie
        ).distinct().count()

        # Chiffre d'affaires (commandes PAYÉES)
        commandes_payees = Commande.objects.filter(
            lignes__pharmacie=pharmacie,
            statut='PAYE'
        ).distinct()

        ca_total = sum(c.total for c in commandes_payees)

        # Commandes récentes
        commandes_recentes = Commande.objects.filter(
            lignes__pharmacie=pharmacie
        ).distinct().order_by('-date_creation')[:5]

        return Response({
            'total_produits': total_produits,
            'produits_en_rupture': produits_en_rupture,
            'produits_alerte': produits_alerte,
            'commandes_attente': commandes_attente,
            'commandes_total': commandes_total,
            'ca_total': float(ca_total),
            'commandes_recentes': CommandeSerializer(commandes_recentes, many=True).data,
        })


# ==================== 2. GESTION DES STOCKS ====================

class GererStockView(APIView):
    """Gestion des stocks de la pharmacie"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)
            stocks = Stock.objects.filter(pharmacie_detentrice=pharmacie)
            return Response(StockSerializer(stocks, many=True).data)
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Pharmacien ou pharmacie non trouvé"}, status=404)

    def post(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Pharmacien ou pharmacie non trouvé"}, status=404)

        medicament_id = request.data.get('medicament_id')
        quantite = request.data.get('quantite', 0)
        seuil_alerte = request.data.get('seuil_alerte', 10)
        date_peremption = request.data.get('date_peremption')

        medicament = get_object_or_404(Medicament, id=medicament_id)

        stock, created = Stock.objects.get_or_create(
            produit_concerne=medicament,
            pharmacie_detentrice=pharmacie,
            defaults={
                'quantite_actuelle_en_stock': quantite,
                'seuil_alerte': seuil_alerte,
                'date_peremption': date_peremption,
            }
        )

        if not created:
            stock.quantite_actuelle_en_stock = quantite
            stock.seuil_alerte = seuil_alerte
            stock.date_peremption = date_peremption
            stock.save()

        return Response(StockSerializer(stock).data)


class UpdateStockView(APIView):
    """Mettre à jour la quantité d'un stock"""
    permission_classes = [IsAuthenticated]

    def patch(self, request, stock_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)
            stock = get_object_or_404(Stock, id=stock_id, pharmacie_detentrice=pharmacie)
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Non autorisé"}, status=403)

        quantite = request.data.get('quantite')
        if quantite is not None:
            stock.quantite_actuelle_en_stock = quantite
            stock.save()

        return Response(StockSerializer(stock).data)


class AlertesStockView(APIView):
    """Voir les stocks sous seuil d'alerte"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)
            alertes = Stock.objects.filter(
                pharmacie_detentrice=pharmacie,
                quantite_actuelle_en_stock__lte=models.F('seuil_alerte')
            )
            return Response(StockSerializer(alertes, many=True).data)
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Pharmacien ou pharmacie non trouvé"}, status=404)


# ==================== 3. GESTION DES COMMANDES ====================

class CommandesPharmacieView(APIView):
    """Liste des commandes concernant cette pharmacie"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Pharmacien ou pharmacie non trouvé"}, status=404)

        filtre = request.query_params.get('filtre', 'toutes')
        queryset = Commande.objects.filter(lignes__pharmacie=pharmacie).distinct()

        if filtre == 'en_attente':
            queryset = queryset.filter(statut='EN_ATTENTE')
        elif filtre == 'payees':
            queryset = queryset.filter(statut='PAYE')

        queryset = queryset.order_by('-date_creation')
        return Response(CommandeSerializer(queryset, many=True).data)


class DetailCommandePharmacieView(APIView):
    """Détail d'une commande pour la pharmacie"""
    permission_classes = [IsAuthenticated]

    def get(self, request, commande_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)
            commande = get_object_or_404(
                Commande,
                id=commande_id,
                lignes__pharmacie=pharmacie
            )
            return Response(CommandeSerializer(commande).data)
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Non autorisé"}, status=403)


class ValiderCommandeView(APIView):
    """Valider qu'une commande a été préparée"""
    permission_classes = [IsAuthenticated]

    def post(self, request, commande_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)
            commande = get_object_or_404(
                Commande,
                id=commande_id,
                lignes__pharmacie=pharmacie
            )
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Non autorisé"}, status=403)

        if commande.statut != 'PAYE':
            return Response({"error": "La commande n'est pas encore payée"}, status=400)

        # Mettre à jour le stock
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


# ==================== 4. GESTION DES MÉDICAMENTS ====================

class GererMedicamentView(APIView):
    """CRUD des médicaments (ajout, modification)"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
        except Pharmacien.DoesNotExist:
            return Response({"error": "Pharmacien non trouvé"}, status=404)

        data = {
            'nom_commercial': request.data.get('nom'),
            'description': request.data.get('description', ''),
            'posologie_standard': request.data.get('posologie', ''),
            'prix_vente': request.data.get('prix', 0),
        }

        serializer = MedicamentSerializer(data=data)
        if serializer.is_valid():
            medicament = serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

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


class CatalogueMedicamentsView(APIView):
    """Liste des médicaments disponibles"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        medicaments = Medicament.objects.all().order_by('nom_commercial')
        return Response(MedicamentSerializer(medicaments, many=True).data)


# ==================== 5. SCAN ORDONNANCE ====================

class ScannerOrdonnanceView(APIView):
    """Scanner le code sécurité d'une ordonnance"""
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
    """Valider et préparer une ordonnance"""
    permission_classes = [IsAuthenticated]

    def post(self, request, ordonnance_id):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)
            ordonnance = get_object_or_404(Ordonnance, id=ordonnance_id)
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Non autorisé"}, status=403)

        # Vérifier les stocks
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

        # Créer une commande automatique à partir de l'ordonnance
        with transaction.atomic():
            commande = Commande.objects.create(
                patient=ordonnance.patient_beneficiaire,
                total=0,
                statut='PAYE',  # Ordonnance validée = payée par la mutuelle/assurance
                methode_retrait='RETRAIT'
            )

            total_commande = 0
            for detail in details:
                prix = detail.medicament.prix_vente
                ligne = LigneCommande.objects.create(
                    commande=commande,
                    produit=detail.medicament,
                    pharmacie=pharmacie,
                    quantite=detail.quantite_boites,
                    prix_unitaire=prix
                )
                total_commande += prix * detail.quantite_boites

                # Décrémenter le stock
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
    """Statistiques de vente de la pharmacie"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            pharmacien = Pharmacien.objects.get(compte_utilisateur=request.user)
            pharmacie = Pharmacie.objects.get(id=pharmacien.id)
        except (Pharmacien.DoesNotExist, Pharmacie.DoesNotExist):
            return Response({"error": "Non autorisé"}, status=403)

        from django.db.models import Sum, Count
        from django.db.models.functions import TruncMonth

        # Ventes par mois
        ventes_par_mois = LigneCommande.objects.filter(
            pharmacie=pharmacie,
            commande__statut='PAYE'
        ).annotate(
            mois=TruncMonth('commande__date_creation')
        ).values('mois').annotate(
            total_ventes=Sum('quantite'),
            ca=Sum('prix_unitaire')
        ).order_by('-mois')[:12]

        # Top médicaments vendus
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