from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

from lamessin_app.models import Consultation
from lamessin_app.serializers import ConsultationSerializer


class EnregistrerSoin(APIView):

    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not request.user.est_un_compte_medecin:
            return Response({"error": "Accès réservé aux médecins"}, status=403)

        serializer = ConsultationSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UploadDocumentMedicalView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        fichier = request.FILES.get('document')
        if not fichier:
            return Response({"error": "Aucun fichier fourni"}, status=400)

        if request.user.est_un_compte_medecin:
            consultation_id = request.data.get('consultation_id')
            consultation = get_object_or_404(Consultation, id=consultation_id)
            consultation.document_joint = fichier
            consultation.save()
            return Response({"success": True, "message": "Document enregistré"})

        return Response({"error": "Action non autorisée"}, status=403)