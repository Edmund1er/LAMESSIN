#LAMESSIN - Application de Gestion de Santé

###  Pré-requis (Installation des outils)

Avant de commencer, assurons-nous d'avoir installé :
* **Python 3.10+** pour Django
* **Flutter SDK** la dernière version stable
* **ngrok** pour l'exposition locale
* **Android Studio** avec SDK Android 10+ / API 29+

---


### 1.Backend : Django
<!-- C -->
Le serveur gère l'authentification et la base de données.
1-Installez les dépendances : :  pip install -r requirements.txt
2- Fichier Credentials : si le fichiers est absent créer le fichiers `credentials.py` dans le meme dossiers que le `settings.py` et y mettre ces infos de connexion 
3- appliquer les migrations
   python manage.py makemigrations
    python manage.py sqlmigrate
   python manage.py migrate
4-lancer le serveur



### 2. Frontend : Flutter
L'interface mobile pour les patients.
1-Installez les dépendances :  flutter pub get

2-Lancez l'application : flutter run
    


## 🔒 3. Installation des Fichiers Secrets (Action Requise)

Puisque ces fichiers ne sont pas sur GitHub, ils seront envoyer par développeur principal et ils seront placer précisément dans ces dossiers :

### Dossier : `lamessin_backend/` (Django)


1. **`firebase-auth.json`** : 
   - **Emplacement :** À la racine du dossier backend.Dans le meme dossiers que manage.py
   - **Rôle :** Permet au backend Django de communiquer avec le SDK Admin de Firebase.

### 🔹 Dossier : `lamessin_flutter/` (Mobile)
2. **`google-services.json`** : 
   - **Emplacement :** `android/app/google-services.json`
   - **Rôle :** Indispensable pour la compilation Android. Lie l'application aux services Firebase.



### 3. Procédure de Lancement 

### Étape 1 : Préparer le Backend Django

# Entrer dans le dossier backend
cd lamessin_backend apres avoir activé l'environement si vous en avez 

# Installer les dépendances
pip install -r requirements.txt

# Appliquer les migrations de la base de données
python manage.py makemigrations
python manage.py migrate

# Lancer le serveur
python manage.py runserver

# Commandes Git 
    Sauvegarder et charger son travail :
    
    git add .
    git commit -m "Description du changement effectué"
    git push origin main

    Récupérer le code ou le travail depuis github :

    git pull origin main

Auteur : ALI Pouwedeou Romaric (Développeur principal)# LAMESSIN
