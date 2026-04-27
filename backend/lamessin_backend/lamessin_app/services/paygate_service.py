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

#Initie un paiement mobile money

        if cls.MODE_TEST:
            print(f"MODE TEST - Paiement simule pour {montant} FCFA")
            return {
                'success': True,
                'tx_reference': f'TEST_{identifier}',
                'status': 0,
                'message': 'Mode test - Paiement simule'
            }

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

        print(f"Envoi PayGate - Payload: {payload}")

        try:
            response = requests.post(
                cls.PAY_URL,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30
            )

            print(f"Reponse PayGate - Status: {response.status_code}")
            print(f"Reponse PayGate - Body: {response.text}")

            if response.status_code == 200:
                data = response.json()
                status_code = data.get('status')

                if status_code == 0:
                    return {
                        'success': True,
                        'tx_reference': data.get('tx_reference'),
                        'status': status_code,
                        'message': 'Transaction initiee'
                    }
                elif status_code == 2:
                    return {'success': False, 'error': 'Cle API invalide', 'status': status_code}
                elif status_code == 4:
                    return {'success': False, 'error': 'Parametres invalides', 'status': status_code}
                elif status_code == 6:
                    return {'success': False, 'error': 'Transaction deja existante', 'status': status_code}
                else:
                    return {'success': False, 'error': f'Erreur inconnue: {status_code}'}
            else:
                return {'success': False, 'error': f'Erreur HTTP: {response.status_code}'}

        except requests.exceptions.Timeout:
            return {'success': False, 'error': 'Timeout de connexion'}
        except requests.exceptions.ConnectionError:
            return {'success': False, 'error': 'Erreur de connexion'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    @classmethod
    def verifier_statut(cls, tx_reference: str):

#Verifie le statut d'une transaction

        if cls.MODE_TEST and tx_reference.startswith('TEST_'):
            print(f"MODE TEST - Statut simule: SUCCES")
            return {
                'success': True,
                'status': 'SUCCES',
                'payment_method': 'TEST',
                'payment_reference': 'TEST_123456'
            }

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
                elif status_code == 4:
                    return {'success': False, 'status': 'EXPIRE'}
                elif status_code == 6:
                    return {'success': False, 'status': 'ANNULE'}
                else:
                    return {'success': False, 'status': 'INCONNU'}
            return {'success': False, 'status': 'ERREUR'}
        except Exception as e:
            return {'success': False, 'status': 'ERREUR', 'error': str(e)}

    @classmethod
    def verifier_solde(cls):

#Verifie le solde du compte PayGate
        payload = {"auth_token": cls.API_KEY}

        try:
            response = requests.post(
                "https://paygateglobal.com/api/v1/check-balance",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30
            )

            if response.status_code == 200:
                data = response.json()
                return {
                    'success': True,
                    'flooz': data.get('flooz', 0),
                    'tmoney': data.get('tmoney', 0)
                }
            return {'success': False, 'error': 'Erreur de verification'}
        except Exception as e:
            return {'success': False, 'error': str(e)}
