# SafeNotes
### A Secure Notes App with Biometric Authentication and Local Encrypted Storage

<p align="center">
  <img src="assets/logo.png" alt="SafeNotes Logo" width="120"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/SQLCipher-AES--256-red" alt="SQLCipher"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey" alt="Platform"/>
  <img src="https://img.shields.io/badge/Version-1.0.0-green" alt="Version"/>
</p>

---

## Overview

SafeNotes is a cross-platform mobile application built with Flutter that provides secure local storage for sensitive notes. All note data is encrypted at rest using AES-256 via SQLCipher, and access to the application is protected by biometric authentication (fingerprint and face unlock) with a PIN fallback. No data is ever sent to any external server — everything stays on the device.

This project was developed as a senior capstone project (ITCY 499) at the University of Bahrain, Department of Information Systems, B.Sc. in Cybersecurity, Academic Year 2025-2026.

---

## Features

- **AES-256 Database Encryption** — All notes stored using SQLCipher, unreadable without the correct key
- **Biometric Authentication** — Fingerprint and Face ID/Face Unlock via Android BiometricPrompt and iOS LocalAuthentication
- **PIN Fallback** — SHA-256 hashed PIN stored in Android Keystore / iOS Keychain via flutter_secure_storage
- **Brute Force Protection** — 5 attempt lockout with 30 second cooldown, persisted in secure storage
- **Per-Note Locking** — Individual notes can be locked requiring separate authentication to open
- **Auto-lock** — Configurable inactivity timeout (30 seconds to never)
- **Background Lock** — App locks immediately when sent to background
- **Categories** — Organize notes into color-coded categories
- **Rich Text Editor** — Bold, italic, underline, font size controls
- **Image Attachments** — Attach images to notes
- **Search and Filter** — Real-time search, filter by category, sort by favorite
- **Dark / Light / System Theme** — Configurable from settings
- **Local Only** — No cloud, no accounts, no network required

---

## Security Architecture

```
┌─────────────────────────────────────────────────┐
│              Authentication Layer                │
│   Biometric (Android Keystore / Secure Enclave) │
│            PIN (SHA-256 + Secure Storage)        │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│              Application Layer                   │
│    AppLockService — NoteAuthService              │
│    Auto-lock timer — Background detection        │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│              Storage Layer                       │
│    SQLCipher AES-256 — sqflite_sqlcipher         │
│    PBKDF2 256,000 iterations — 4096 byte pages   │
└─────────────────────────────────────────────────┘
```

---

## Database Schema

```sql
CREATE TABLE notes (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  title       TEXT NOT NULL,
  content     TEXT NOT NULL,
  createdAt   TEXT NOT NULL,
  updatedAt   TEXT NOT NULL,
  isFavorite  INTEGER NOT NULL DEFAULT 0,
  imagePath   TEXT,
  categoryId  TEXT,
  isLocked    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE categories (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  color       INTEGER NOT NULL DEFAULT 0,
  createdAt   TEXT NOT NULL
);
```

---

## Project Structure

```
lib/
├── models/
│   ├── note_model.dart
│   └── category_model.dart
├── screens/
│   ├── login_screen.dart
│   ├── pin_login_screen.dart
│   ├── pin_setup_screen.dart
│   ├── notes_list_screen.dart
│   ├── note_detail_screen.dart
│   ├── rich_note_editor_screen.dart
│   ├── settings_screen.dart
│   └── categories_screen.dart
├── services/
│   ├── database_service.dart
│   ├── pin_service.dart
│   ├── app_lock_service.dart
│   ├── note_auth_service.dart
│   ├── preferences_service.dart
│   └── theme_service.dart
├── widgets/
│   ├── activity_detector.dart
│   └── lock_wrapper.dart
└── main.dart

test/
├── pin_service_test.dart
├── app_lock_service_test.dart
└── preferences_service_test.dart

integration_test/
├── database_service_test.dart
└── performance_test.dart
```

---

## Tech Stack

| Package | Version | Purpose |
|---|---|---|
| flutter_sdk | 3.x | Cross-platform UI framework |
| sqflite_sqlcipher | 3.1.0 | AES-256 encrypted SQLite database |
| flutter_secure_storage | 9.0.0 | Hardware-backed PIN hash storage |
| local_auth | 2.3.0 | Biometric authentication |
| local_auth_android | 1.0.46 | Android BiometricPrompt support |
| crypto | 3.0.3 | SHA-256 PIN hashing |
| shared_preferences | 2.2.2 | Non-sensitive settings storage |
| image_picker | 1.0.7 | Image attachment selection |
| path_provider | 2.1.2 | File path resolution |
| flutter_quill | latest | Rich text editor |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x installed
- Dart SDK 3.x
- Android Studio (for Android SDK and emulator)
- VS Code or Android Studio as IDE
- Physical device or emulator with API level 21+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Fawaz-Alkhayer/Senior-project.git
cd Senior-project/Codes/secure_notes_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

4. Build release APK:
```bash
flutter build apk --release
```

---

## Running Tests

### Unit Tests
```bash
flutter test
```

### Integration Tests (requires physical device or emulator)
```bash
flutter test integration_test/database_service_test.dart
flutter test integration_test/performance_test.dart
```

---

## Test Results

### Component Tests — 19/19 Pass
| Test ID | Component | Test Case | Result |
|---|---|---|---|
| TC-01 | PinService | PIN too short throws exception | Pass |
| TC-02 | PinService | Valid PIN set successfully | Pass |
| TC-03 | PinService | Correct PIN verifies successfully | Pass |
| TC-04 | PinService | Wrong PIN fails verification | Pass |
| TC-05 | PinService | Cleared PIN shows as not set | Pass |
| TC-06 | PinService | Verify PIN after clear returns false | Pass |
| TC-07 | AppLockService | App locked on initial state | Pass |
| TC-08 | AppLockService | unlock() sets isLocked to false | Pass |
| TC-09 | AppLockService | lock() after unlock re-locks app | Pass |
| TC-10 | AppLockService | isPaused is false by default | Pass |
| TC-11 | AppLockService | pauseAutoLock() sets isPaused true | Pass |
| TC-12 | AppLockService | resumeAutoLock() sets isPaused false | Pass |
| TC-13 | AppLockService | Duration 0 disables timer | Pass |
| TC-14 | PreferencesService | Default lock duration is 30 seconds | Pass |
| TC-15 | PreferencesService | Set duration to 60 returns 60 | Pass |
| TC-16 | PreferencesService | Set duration to 0 returns 0 | Pass |
| TC-17 | PreferencesService | Default theme is system | Pass |
| TC-18 | PreferencesService | Set theme dark returns dark | Pass |
| TC-19 | PreferencesService | Set theme light returns light | Pass |

### Integration Tests — 7/7 Pass
| Test ID | Component | Test Case | Result |
|---|---|---|---|
| TC-20 | DatabaseService | Create note and verify stored | Pass |
| TC-21 | DatabaseService | Read note returns correct data | Pass |
| TC-22 | DatabaseService | Update note changes content | Pass |
| TC-23 | DatabaseService | Delete note removes from database | Pass |
| TC-24 | DatabaseService | Toggle favorite updates isFavorite | Pass |
| TC-25 | DatabaseService | Toggle lock updates isLocked | Pass |
| TC-26 | DatabaseService | Read all notes returns list | Pass |

### Performance Tests — Samsung Galaxy S21 Ultra, Android 15
| Test ID | Operation | Result |
|---|---|---|
| PT-01 | Note creation (AES-256 write) | 351ms |
| PT-02 | Note read (AES-256 decrypt) | 12ms |
| PT-03 | Read all notes | 6ms |
| PT-04 | PIN hashing and Keystore write | 138ms |
| PT-05 | PIN verification | 9ms |

---

## Security Testing Summary

| Test | Category | Result |
|---|---|---|
| Database extraction via ADB | Physical Access | Pass |
| SQL injection in note fields | Injection Attack | Pass |
| Back button bypass attempt | Auth Bypass | Pass |
| Task switcher bypass attempt | Auth Bypass | Pass |
| Force stop bypass attempt | Auth Bypass | Pass |
| Logcat plaintext data exposure | Data Leakage | Pass |
| Shared preferences exposure | Data Leakage | Pass |
| PIN brute force attack | Credential Attack | Fixed |

---

## Known Limitations

- SQLCipher encryption key is hardcoded in source code and not stored in the Android Keystore
- No user account system — all data is permanently lost on uninstall with no recovery option
- TOTP-based 2FA recovery was not implemented in this version
- Image attachments are stored as plaintext files — only the file path is encrypted in the database
- No clipboard clearing when the app locks

---

## Development Team

**University of Bahrain — College of Information Technology**
**Department of Information Systems — B.Sc. in Cybersecurity**
**Senior Project ITCY 499 — Academic Year 2025-2026**

| Name | Student ID |
|---|---|
| Jaber Khalid Abdullah Askani | 202207991 |
| Osama Humood Taha Ali | 202210387 |
| Fawaz Ayman Alkhayer | 202202748 |

**Project Supervisor:** Dr. Hadeel Alobaidy

---

## License

This project was developed for academic purposes as part of the University of Bahrain Senior Project requirement. All rights reserved by the development team.
