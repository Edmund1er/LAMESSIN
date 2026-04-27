# lamessin_app/views/ia_views.py
import os
import logging
from datetime import datetime
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, JSONParser
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.conf import settings

from ..services.ai_service import ai_service

logger = logging.getLogger(__name__)


class StatutIAView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(ai_service.get_status())


class ChatbotIAView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser]

    def post(self, request):
        message = request.data.get('message')
        historique = request.data.get('historique', [])

        if not message:
            return Response(
                {'error': 'Le champ message est requis'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            reponse = ai_service.chatbot_medical(message, historique)

            return Response({
                'success': True,
                'reponse': reponse,
                'timestamp': datetime.now().isoformat(),
                'mock_mode': ai_service.mock_mode
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Erreur chatbot: {str(e)}")
            return Response(
                {'error': f'Erreur: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AnalyseOrdonnanceIAView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser]

    def post(self, request):
        texte_ordonnance = request.data.get('texte_ordonnance', '')

        if not texte_ordonnance:
            return Response(
                {'error': 'Le champ texte_ordonnance est requis'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            resultat = ai_service.analyser_ordonnance(texte_ordonnance)

            return Response({
                'success': True,
                'data': resultat,
                'mock_mode': ai_service.mock_mode
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Erreur analyse: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class InteractionMedicamenteuseIAView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser]

    def post(self, request):
        medicaments = request.data.get('medicaments', [])

        if not medicaments:
            return Response(
                {'error': 'La liste des medicaments est requise'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(medicaments) < 2:
            return Response(
                {'error': 'Veuillez fournir au moins 2 medicaments'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            resultat = ai_service.verifier_interaction_medicamenteuse(medicaments)

            return Response({
                'success': True,
                'data': resultat,
                'mock_mode': ai_service.mock_mode,
                'medicaments_analyses': medicaments
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Erreur verification: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ResumeMedicalIAView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser]

    def post(self, request):
        texte = request.data.get('texte', '')

        if not texte:
            return Response(
                {'error': 'Le champ texte est requis'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(texte) < 50:
            return Response(
                {'error': 'Le texte est trop court (minimum 50 caracteres)'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            resume = ai_service.resumer_carnet_sante(texte)

            return Response({
                'success': True,
                'resume': resume,
                'longueur_originale': len(texte),
                'mock_mode': ai_service.mock_mode
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Erreur resume: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


@api_view(["POST"])
@permission_classes([AllowAny])
def assistant_ia(request):
    prompt = request.data.get("prompt", "")

    if not prompt:
        return Response({"error": "Le champ prompt est requis"}, status=400)

    try:
        reponse = ai_service.chatbot_medical(prompt)

        return Response({
            "reponse": reponse,
            "mock_mode": ai_service.mock_mode
        })
    except Exception as e:
        return Response({"error": str(e)}, status=500)