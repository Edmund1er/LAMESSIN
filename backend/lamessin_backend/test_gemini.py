import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv('api.env')

# Configuration de la clé
genai.configure(api_key=os.environ.get("GEMINI_KEY"))

try:
    # Initialisation du modèle avec la syntaxe stable
    model = genai.GenerativeModel('gemini-1.5-flash')

    response = model.generate_content("Bonjour, est-ce que ça marche enfin ?")

    print("--- TEST RÉUSSI ---")
    print("Réponse :", response.text)
except Exception as e:
    print(f"Erreur avec la méthode stable : {e}")