#LAMESSIN - Application de Gestion de Santé

### Backend : Django
<!-- C -->
Le serveur gère l'authentification et la base de données.
1-Installez les paquets :  pip install -r requirements.txt
2- Fichier Credentials : si le fichiers est absent créer le fichiers `credentials.py` dans le meme dossiers que le `settings.py` et y mettre ces infos de connexion 
3- appliquer les migrations
   python manage.py makemigrations
    python manage.py sqlmigrate
   python manage.py migrate
4-lancer le serveur



### 2. Frontend : Flutter
L'interface mobile pour les patients.
1-Installez les paquets :  flutter pub get

2-Lancez l'application : flutter run
    
Commandes Git 
    Sauvegarder et charger son travail :
    
    git add .
    git commit -m "Description du changement effectué"
    git push origin main

    Récupérer le code ou le travail depuis github :

    git pull origin main

Auteur : ALI Pouwedeou Romaric (Développeur principal)