# lamessin_app/services/paygate_service.py

import json
import requests
from django.conf import settings
import os

class PayGateService:

    API_KEY = "892019cc-1ba1-4c3e-8f28-8a8a6b59084f"

    BASE_URL = "https://paygateglobal.com/api/v1"
    PAY_URL = f"{BASE_URL}/pay"
    STATUS_URL = f"{BASE_URL}/status"

    MODE_TEST = True

    @classmethod
    def initier_paiement(cls, montant: float, telephone: str, operateur: str, identifier: str):
        """Initie un paiement mobile money"""

        # MODE TEST : Simuler un paiement réussi
        if cls.MODE_TEST:
            print(f"🔧 MODE TEST - Paiement simulé pour {montant} FCFA")
            return {
                'success': True,
                'tx_reference': f'TEST_{identifier}',
                'status': 0,
                'message': 'Mode test - Paiement simulé'
            }

        # Code réel (désactivé en mode test)
        phone = ''.join(filter(str.isdigit, telephone))
        if len(phone) > 8:
            phone = phone[-8:]

        provider = "MOOV" if operateur.upper() == "FLOOZ" else "TOGOCEL"

        payload = {
            "auth_token": cls.API_KEY,
            "phone_number": phone,
            "amount": int(montant),
            "description": f"Commande LAMESSIN {identifier}",
            "identifier": identifier,
            "network": operateur.upper()
        }

        try:
            response = requests.post(
                cls.PAY_URL,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30
            )

            if response.status_code == 200:
                data = response.json()
                status_code = data.get('status')

                if status_code == 0:
                    return {
                        'success': True,
                        'tx_reference': data.get('tx_reference'),
                        'status': status_code,
                        'message': 'Transaction initiée'
                    }
                else:
                    return {'success': False, 'error': f'Erreur: {status_code}'}
            else:
                return {'success': False, 'error': f'Erreur HTTP: {response.status_code}'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    @classmethod
    def verifier_statut(cls, tx_reference: str):
        """Vérifie le statut d'une transaction"""

        # MODE TEST : Toujours retourner SUCCES
        if cls.MODE_TEST and tx_reference.startswith('TEST_'):
            print(f"🔧 MODE TEST - Statut simulé: SUCCES")
            return {
                'success': True,
                'status': 'SUCCES',
                'payment_method': 'TEST',
                'payment_reference': 'TEST_123456'
            }

        # Code réel
        payload = {
            "auth_token": cls.API_KEY,
            "tx_reference": tx_reference
        }

        try:
            response = requests.post(
                cls.STATUS_URL,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30
            )

            if response.status_code == 200:
                data = response.json()
                status_code = data.get('status')

                if status_code == 0:
                    return {
                        'success': True,
                        'status': 'SUCCES',
                        'payment_method': data.get('payment_method'),
                        'payment_reference': data.get('payment_reference')
                    }
                elif status_code == 2:
                    return {'success': False, 'status': 'EN_ATTENTE'}
                else:
                    return {'success': False, 'status': 'ECHEC'}
            return {'success': False, 'status': 'ERREUR'}
        except Exception as e:
            return {'success': False, 'status': 'ERREUR', 'error': str(e)}