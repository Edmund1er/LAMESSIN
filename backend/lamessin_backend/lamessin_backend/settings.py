# lamessin_backend/settings.py
"""
Django settings for lamessin_backend project.
Optimisé pour Flutter & Firebase - Configuration Complète
"""

import os
from pathlib import Path
from datetime import timedelta
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
    print(f"✓ Fichier .env chargé depuis {ENV_PATH}")

    groq_key = os.getenv('GROQ_API_KEY')
    if groq_key:
        print(f"✓ GROQ_API_KEY trouvée (commence par: {groq_key[:15]}...)")
    else:
        print("⚠️ GROQ_API_KEY non trouvée dans api.env - Veuillez vous inscrire sur console.groq.com")
else:
    print(f"⚠️ Fichier api.env introuvable à {ENV_PATH}")

# ====================================================================================================
# CONFIGURATION DES ACCÈS (BASE DE DONNÉES)
# ====================================================================================================
try:
    from . import credentials as db_creds
except ImportError:
    db_creds = None

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-*xx#hp=o=!zq@46*b#n#jc!2wiubmmz-l8dnh%p8fy6m=5$hph'

DEBUG = True

ALLOWED_HOSTS = ['*']

# ====================================================================================================
# APPLICATION DEFINITION
# ====================================================================================================

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'lamessin_app',
]

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

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
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

WSGI_APPLICATION = 'lamessin_backend.wsgi.application'

# ====================================================================================================
# DATABASE CONFIGURATION
# ====================================================================================================

if db_creds:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': db_creds.DB_NAME,
            'USER': db_creds.DB_USER,
            'PASSWORD': db_creds.DB_PASSWORD,
            'HOST': db_creds.DB_HOST,
            'PORT': db_creds.DB_PORT,
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
# CORS & SÉCURITÉ
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
# FICHIERS STATIQUES ET MÉDIAS
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
            print("Firebase Admin SDK initialisé avec succès !")
    except Exception as e:
        print(f"Erreur initialisation Firebase : {e}")
else:
    print("Attention : firebase-auth.json introuvable. Les notifications ne fonctionneront pas.")

# ====================================================================================================
# INTERNATIONALISATION
# ====================================================================================================

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'