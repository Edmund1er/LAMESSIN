# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**LAMESSIN** is a comprehensive healthcare management platform supporting three user roles:
- **Patients:** Book appointments, access medical records, view prescriptions
- **Doctors (Médecins):** Manage patient appointments, consultations, prescriptions, availability
- **Pharmacists (Pharmaciens):** Manage pharmacy inventory, process prescriptions, track orders

Multi-language support with localized UI for each role.

## Architecture

### Backend Stack
- **Framework:** Django (Python 3.10+)
- **Authentication:** Firebase Authentication + JWT
- **Cloud Services:** 
  - Google Cloud Firestore (database)
  - Google Cloud Storage (file uploads)
  - Google Generative AI (Gemini for healthcare insights)
- **Admin SDK:** Firebase Admin SDK 7.2.0
- **Email/Messaging:** Firebase Cloud Messaging (FCM)

### Frontend Stack
- **Framework:** Flutter (^3.10.4)
- **Targets:** Android, iOS (primary mobile focus)
- **Features:**
  - Push notifications (Firebase Cloud Messaging)
  - Geolocation (geolocator 10.1.0)
  - Maps (google_maps_flutter 2.5.0)
  - AI Integration (google_generative_ai 0.4.7)
  - Local persistence (shared_preferences 2.2.2)
- **Design:** Material Design with role-specific UI (patient/doctor/pharmacist)

## Development Setup

### Prerequisites
- **Python 3.10+**
- **Flutter SDK** (latest stable)
- **Android Studio** with SDK 10+ (API 29+)
- **Firebase Project** (for credentials)

### Backend

```bash
cd backend/lamessin_backend

# Create Python virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up credentials.py (see Secret Files section below)

# Create migrations (first time)
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Run development server (available on localhost:8000)
python manage.py runserver
```

### Frontend

```bash
cd lamessin_flutter

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build APK
flutter build apk

# Run tests
flutter test
```

## 🔒 Secret Files (Action Required)

These files are NOT in git and must be provided by the team lead:

### Backend (`lamessin_backend/`)
- **`firebase-auth.json`** → At root of `lamessin_backend/` (same directory as `manage.py`)
  - Purpose: Firebase Admin SDK authentication for Django backend
  - Required to communicate with Firestore and Cloud Storage

### Frontend (`lamessin_flutter/`)
- **`android/app/google-services.json`** 
  - Purpose: Binds Android app to Firebase services (required for compilation)
  - Must be placed exactly at `android/app/google-services.json`

## Key Directories

```
LAMESSIN/
├── backend/
│   └── lamessin_backend/           # Django backend
│       ├── lamessin_app/           # Main app
│       │   └── models.py
│       ├── lamessin_backend/       # Settings
│       │   └── settings.py         # Firebase config, Firestore
│       ├── requirements.txt
│       ├── manage.py
│       └── firebase-auth.json      # SECRET - Provided by lead dev
├── lamessin_flutter/               # Flutter frontend
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── patient/            # Patient-specific screens
│   │   │   ├── doctor/             # Doctor-specific screens
│   │   │   └── pharmacist/         # Pharmacist-specific screens
│   │   └── models/                 # Data models
│   ├── android/
│   │   └── app/google-services.json # SECRET - Provided by lead dev
│   ├── pubspec.yaml
│   └── assets/images/              # Role-specific background images
├── docs/
│   ├── CALENDRIER D'implementation.pdf  # Project timeline
│   └── cahier de charge PPE.docx       # Requirements spec
└── MODELS.PY                       # (Check purpose with team)
```

## Important Notes

### Firebase Configuration
- Backend uses Firebase Admin SDK to manage authentication and Firestore
- Frontend uses Firebase Cloud Messaging for notifications
- Both require valid `google-services.json` and `firebase-auth.json`

### Role-Based UI
- App dynamically loads different screens based on user role (Patient/Doctor/Pharmacist)
- Background images for each role are in `assets/images/fond_*`
- Permissions and navigation are role-specific

### Geolocation & Maps
- Google Maps requires valid API key (configure in `AndroidManifest.xml`)
- Geolocation permissions must be requested at runtime
- Test with realistic location data

### Healthcare Data Security
- Patient medical records are sensitive — ensure proper access control in Firestore
- Prescriptions should only be visible to authorized parties
- Consider HIPAA/GDPR compliance for production

### Push Notifications
- FCM handles patient appointment reminders and doctor notifications
- Test notification routing across roles

## Common Tasks

### Add a new screen for a role
1. Create file in `lib/screens/{role}/{feature_name}.dart`
2. Import role-specific providers/models
3. Use Firebase auth to verify user role on load
4. Test navigation in role's app flow

### Connect to Firestore
1. Import `google_cloud_firestore` dependencies
2. Use Firebase Admin SDK on backend (Django)
3. Configure Firestore rules for role-based access
4. Test with both Android and iOS

### Test Push Notifications
1. Ensure `firebase-messaging` dependency is installed
2. Test with Firebase Console → Cloud Messaging
3. Verify notifications route to correct user role
4. Check local notification display (fallback when app closed)

### Debug Firebase Issues
- Check Firebase Console for auth/Firestore errors
- Use Firebase Emulator Suite for local development
- Monitor Firestore usage for quota overages
