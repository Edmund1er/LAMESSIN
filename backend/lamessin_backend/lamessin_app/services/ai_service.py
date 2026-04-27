# lamessin_app/services/ai_service.py
import os
import json
import logging
from typing import Optional, Dict, Any, List

logger = logging.getLogger(__name__)


class AIService:
    """Service pour interagir avec l'API GROQ"""

    def __init__(self):
        self.api_key = os.getenv("GROQ_API_KEY")

        if not self.api_key:
            print("GROQ_API_KEY non trouvee dans api.env")
            print("Obtenez une cle gratuite sur: https://console.groq.com")
            self.mock_mode = True
            return

        try:
            from groq import Groq
            self.client = Groq(api_key=self.api_key)
            self.model_puissant = "llama-3.3-70b-versatile"
            self.model_rapide = "llama-3.1-8b-instant"
            self.model_specifique = "mixtral-8x7b-32768"
            print("GROQ API initialisee avec succes")
            self.mock_mode = False
        except ImportError:
            print("Package groq non installe - pip install groq")
            self.mock_mode = True
        except Exception as e:
            print(f"Erreur GROQ: {str(e)[:100]}")
            self.mock_mode = True

    def chatbot_medical(self, message: str, historique: Optional[List] = None) -> str:
        """Chatbot medical pour patients Lamessin"""

        if self.mock_mode:
            return self._mock_chatbot_response(message)

        try:
            system_prompt = """
            Tu es l'assistant medical de l'application Lamessin.
            
            REGLES IMPERATIVES A RESPECTER:
            1. Tu ne donnes JAMAIS de diagnostic medical
            2. Tu ne prescris JAMAIS de medicaments
            3. Pour tout symptome grave, oriente vers une consultation medicale
            4. Tu ajoutes systematiquement: "Information generale - Consultez toujours un medecin"
            5. Tu restes empathique et professionnel
            6. Tu reponds en francais
            """

            messages = [
                {"role": "system", "content": system_prompt}
            ]

            if historique:
                for msg in historique[-10:]:
                    role = "user" if msg.get("role") == "user" else "assistant"
                    messages.append({"role": role, "content": msg.get("content", "")})

            messages.append({"role": "user", "content": message})

            response = self.client.chat.completions.create(
                model=self.model_puissant,
                messages=messages,
                max_tokens=1000,
                temperature=0.7
            )

            return response.choices[0].message.content

        except Exception as e:
            logger.error(f"Erreur chatbot GROQ: {e}")
            return self._mock_chatbot_response(message, error=str(e))

    def analyser_ordonnance(self, texte_extraire: str) -> Dict[str, Any]:
        """
        Analyse un texte extrait d'ordonnance

        Note: GROQ ne supporte pas les images directement.
        Pour l'analyse d'images, utilisez un OCR d'abord.
        """

        if self.mock_mode:
            return self._mock_ordonnance_response()

        try:
            prompt = f"""
            Analyse ce texte extrait d'une ordonnance medicale et extrait les informations.
            
            Texte: {texte_extraire}
            
            Reponds UNIQUEMENT en JSON avec cette structure:
            {{
                "medicaments": [
                    {{
                        "nom": "nom du medicament",
                        "dosage": "dosage",
                        "frequence": "frequence de prise",
                        "duree": "duree du traitement",
                        "instructions": "instructions particulieres"
                    }}
                ],
                "date_prescription": "date au format AAAA-MM-JJ",
                "medecin": "nom du medecin",
                "remarques": "autres informations"
            }}
            
            Si une information n'est pas trouvee, mets une chaine vide.
            """

            response = self.client.chat.completions.create(
                model=self.model_puissant,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=1500,
                temperature=0.3
            )

            text = response.choices[0].message.content.strip()

            if text.startswith('```json'):
                text = text[7:]
            if text.startswith('```'):
                text = text[3:]
            if text.endswith('```'):
                text = text[:-3]

            return json.loads(text)

        except Exception as e:
            logger.error(f"Erreur analyse ordonnance: {e}")
            return self._mock_ordonnance_response(error=str(e))

    def verifier_interaction_medicamenteuse(self, medicaments: List[str]) -> Dict[str, Any]:
        """Verifie les interactions entre medicaments"""

        if self.mock_mode:
            return self._mock_interaction_response(medicaments)

        try:
            prompt = f"""
            Analyse les interactions medicamenteuses entre: {', '.join(medicaments)}
            
            Reponds UNIQUEMENT en JSON:
            {{
                "interactions": [
                    {{
                        "medicaments": ["med1", "med2"],
                        "gravite": "Faible/Moyen/Eleve/Critique",
                        "description": "description de l'interaction",
                        "recommandation": "conduite a tenir"
                    }}
                ],
                "recommandation_generale": "recommandation d'ensemble",
                "avertissement": "Ceci est une analyse automatisee - Confirmer avec un professionnel"
            }}
            
            Si aucune interaction connue, renvoie une liste vide.
            """

            response = self.client.chat.completions.create(
                model=self.model_specifique,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=1000,
                temperature=0.3
            )

            text = response.choices[0].message.content.strip()

            if text.startswith('```json'):
                text = text[7:]
            if text.startswith('```'):
                text = text[3:]
            if text.endswith('```'):
                text = text[:-3]

            return json.loads(text)

        except Exception as e:
            logger.error(f"Erreur verification interactions: {e}")
            return self._mock_interaction_response(medicaments, error=str(e))

    def resumer_carnet_sante(self, texte: str) -> str:
        """Resume un long texte medical"""

        if self.mock_mode:
            return self._mock_resume_response(texte)

        try:
            prompt = f"""
            Tu es un medecin resumant un carnet de sante ou historique medical.
            
            Tache: Resume ce texte medical de facon claire, precise et professionnelle.
            
            Structure a suivre:
            1. Informations essentielles (allergies, maladies chroniques)
            2. Traitements en cours
            3. Consultations/evenements recents importants
            4. Recommandations
            
            Texte a resumer:
            {texte[:8000]}
            
            Resume (concis mais complet):
            """

            response = self.client.chat.completions.create(
                model=self.model_puissant,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=1000,
                temperature=0.5
            )

            return response.choices[0].message.content

        except Exception as e:
            logger.error(f"Erreur resume: {e}")
            return self._mock_resume_response(texte, error=str(e))

    def get_status(self) -> Dict[str, Any]:
        """Retourne le statut du service"""
        return {
            "service": "GROQ AI",
            "mock_mode": self.mock_mode,
            "api_key_configured": bool(self.api_key),
            "message": "Mode developpement" if self.mock_mode else "Mode reel - API operationnelle",
            "modeles_disponibles": ["llama-3.3-70b", "llama-3.1-8b", "mixtral-8x7b"]
        }

    def _mock_chatbot_response(self, message: str, error: str = None) -> str:
        return f"""Information generale

Merci pour votre question: "{message[:80]}"

Ce que je peux vous dire:
- Les informations fournies sont generales
- Consultez votre medecin traitant pour une evaluation personnalisee
- En cas d'urgence, appelez le 15 (SAMU)

Note: L'API GROQ sera active des que la cle sera configuree dans api.env"""

    def _mock_ordonnance_response(self, error: str = None) -> Dict[str, Any]:
        return {
            "medicaments": [
                {
                    "nom": "Paracetamol 500mg",
                    "dosage": "1 comprime",
                    "frequence": "Matin et soir",
                    "duree": "5 jours",
                    "instructions": "A prendre avec de l'eau"
                },
                {
                    "nom": "Vitamine C 1000mg",
                    "dosage": "1 comprime",
                    "frequence": "1 fois par jour",
                    "duree": "10 jours",
                    "instructions": "A prendre le matin"
                }
            ],
            "date_prescription": "2025-04-27",
            "medecin": "Dr. Martin",
            "remarques": "Mode developpement - Analyse simulee",
            "_mock": True
        }

    def _mock_interaction_response(self, medicaments: List[str], error: str = None) -> Dict[str, Any]:
        return {
            "interactions": [
                {
                    "medicaments": medicaments[:2] if len(medicaments) >= 2 else medicaments,
                    "gravite": "Informationnelle",
                    "description": f"Interaction entre {', '.join(medicaments)} - A verifier avec un professionnel",
                    "recommandation": "Consultez votre medecin ou pharmacien"
                }
            ],
            "recommandation_generale": "Toute association medicamenteuse doit etre validee par un professionnel de sante",
            "avertissement": "Analyse simulee - Mode developpement",
            "_mock": True
        }

    def _mock_resume_response(self, texte: str, error: str = None) -> str:
        return f"""Resume - Mode developpement

Document: {len(texte)} caracteres

Resume simule:
- Document medical a analyser
- Consultation recommandee avec votre medecin
- API GROQ sera disponible sous peu

Extrait:
{texte[:200]}...

Avertissement: Resume simule - Mode developpement"""


ai_service = AIService()
