# lamessin_backend/settings.py
"""
Django settings for lamessin_backend project.
Optimisé pour Flutter & Firebase - Configuration Complète
"""

import os
from pathlib import Path
from datetime import timedelta
from django.utils import timezone
import firebase_admin
from firebase_admin import credentials as fb_creds
from dotenv import load_dotenv

# ====================================================================================================
# CHARGER LES VARIABLES D'ENVIRONNEMENT DEPUIS API.ENV
# ====================================================================================================
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / 'api.env'

if ENV_PATH.exists():
    load_dotenv(ENV_PATH)
    print(f"[OK] Fichier .env charge depuis {ENV_PATH}")

    groq_key = os.getenv('GROQ_API_KEY')
    if groq_key:
        print(f"[OK] GROQ_API_KEY trouvee (commence par: {groq_key[:15]}...)")
    else:
        print("[WARN] GROQ_API_KEY non trouvee dans api.env - Veuillez vous inscrire sur console.groq.com")
else:
    print(f"[WARN] Fichier api.env introuvable a {ENV_PATH}")

# ====================================================================================================
# CONFIGURATION DES ACCES (BASE DE DONNEES)
# ====================================================================================================
try:
    from . import  credentials
except ImportError:
    credentials = None

SECRET_KEY = 'django-insecure-*xx#hp=o=!zq@46*b#n#jc!2wiubmmz-l8dnh%p8fy6m=5$hph'

DEBUG = True

ALLOWED_HOSTS = ['*']

# ====================================================================================================
# APPLICATION DEFINITION - SANS UNFOLD
# ====================================================================================================

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'lamessin_app',
]

# ====================================================================================================
# TEMPLATES
# ====================================================================================================

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [
            os.path.join(BASE_DIR, 'lamessin_app/templates'),
        ],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# ====================================================================================================
# MIDDLEWARE
# ====================================================================================================

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'lamessin_backend.urls'

WSGI_APPLICATION = 'lamessin_backend.wsgi.application'

# ====================================================================================================
# DATABASE CONFIGURATION
# ====================================================================================================

if credentials:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': credentials.DB_NAME,
            'USER': credentials.DB_USER,
            'PASSWORD': credentials.DB_PASSWORD,
            'HOST': credentials.DB_HOST,
            'PORT': credentials.DB_PORT,
        }
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# ====================================================================================================
# AUTHENTIFICATION & JWT CONFIGURATION
# ====================================================================================================

AUTH_USER_MODEL = 'lamessin_app.Utilisateur'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
}
SIMPLEUI_CONFIG = {
    'system_keep': False,
    'dynamic': True,
    'menus': [
        {
            'name': 'Accueil',
            'icon': 'home',
            'url': '/admin/',
        },
        {
            'name': 'Utilisateurs & Rôles',
            'icon': 'people',
            'models': [
                {'name': 'Utilisateurs', 'icon': 'person', 'url': '/admin/lamessin_app/utilisateur/'},
                {'name': 'Patients', 'icon': 'favorite', 'url': '/admin/lamessin_app/patient/'},
                {'name': 'Médecins', 'icon': 'medical_services', 'url': '/admin/lamessin_app/medecin/'},
                {'name': 'Pharmaciens', 'icon': 'local_pharmacy', 'url': '/admin/lamessin_app/pharmacien/'},
            ]
        },
        {
            'name': 'Rendez-vous & Consultations',
            'icon': 'calendar_today',
            'models': [
                {'name': 'Rendez-vous', 'icon': 'event', 'url': '/admin/lamessin_app/rendezvous/'},
                {'name': 'Consultations', 'icon': 'assignment', 'url': '/admin/lamessin_app/consultation/'},
            ]
        },
        {
            'name': 'Pharmacie & Stocks',
            'icon': 'local_pharmacy',
            'models': [
                {'name': 'Pharmacies', 'icon': 'store', 'url': '/admin/lamessin_app/pharmacie/'},
                {'name': 'Médicaments', 'icon': 'medication', 'url': '/admin/lamessin_app/medicament/'},
                {'name': 'Stocks', 'icon': 'inventory', 'url': '/admin/lamessin_app/stock/'},
            ]
        },
        {
            'name': 'Ordonnances & Commandes',
            'icon': 'receipt',
            'models': [
                {'name': 'Ordonnances', 'icon': 'description', 'url': '/admin/lamessin_app/ordonnance/'},
                {'name': 'Commandes', 'icon': 'shopping_cart', 'url': '/admin/lamessin_app/commande/'},
            ]
        },
        {
            'name': 'Établissements',
            'icon': 'apartment',
            'models': [
                {'name': 'Hôpitaux', 'icon': 'local_hospital', 'url': '/admin/lamessin_app/hopital/'},
                {'name': 'Pharmacies', 'icon': 'local_pharmacy', 'url': '/admin/lamessin_app/pharmacie/'},
            ]
        },
        {
            'name': 'Notifications',
            'icon': 'notifications',
            'url': '/admin/lamessin_app/notification/',
        },
    ],
    'LANGUAGE_CHOICE': False,
    'RECENT_ACTIONS': True,
    'QUICK_ACTIONS': [
        {
            'name': 'Tableau de bord analytique',
            'icon': 'monitoring',
            'url': '/lamessin_admin/',
            'description': 'Voir le dashboard principal'
        },
        {
            'name': 'Statistiques détaillées',
            'icon': 'analytics',
            'url': '/lamessin_admin/statistiques/',
            'description': 'Rapport complet des stats'
        },
    ],
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
}

# ====================================================================================================
# CORS & SECURITE
# ====================================================================================================

CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_HEADERS = [
    "accept",
    "authorization",
    "content-type",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
    "ngrok-skip-browser-warning",
]

# ====================================================================================================
# FICHIERS STATIQUES ET MEDIAS
# ====================================================================================================

STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# ====================================================================================================
# FIREBASE ADMIN SDK INITIALISATION
# ====================================================================================================

FIREBASE_KEY_PATH = os.path.join(BASE_DIR, 'firebase-auth.json')

if os.path.exists(FIREBASE_KEY_PATH):
    try:
        if not firebase_admin._apps:
            certification_obj = fb_creds.Certificate(FIREBASE_KEY_PATH)
            firebase_admin.initialize_app(certification_obj)
            print("[OK] Firebase Admin SDK initialise avec succes !")
    except Exception as e:
        print(f"[ERROR] Erreur initialisation Firebase : {e}")
else:
    print("[WARN] firebase-auth.json introuvable. Les notifications ne fonctionneront pas.")

# ====================================================================================================
# INTERNATIONALISATION
# ====================================================================================================

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'