# CLAUDE.md - Study City Development Guide

## App Overview

Study City is a gamified study tracking Flutter Web application. Students log study sessions with a timer, review learned material using the SM2 spaced repetition algorithm, and earn EXP/coins to upgrade buildings in their virtual city. The core loop is: **Study → Earn Rewards → Build Your City → Review → Repeat**.

## Tech Stack

- **Flutter Web** (Dart) — UI framework
- **Firebase Core / Auth / Firestore / Messaging** — backend services
- **flutter_riverpod** — state management (ChangeNotifierProvider)
- **go_router** — declarative routing with auth redirect
- **fl_chart** — bar charts and pie charts for statistics
- **wakelock_plus** — prevent screen sleep during study timer
- **intl** — date formatting

## Folder Structure

```
lib/
├── main.dart                 # App entry point: Firebase init + ProviderScope
├── firebase_options.dart     # Firebase config (gitignored, placeholder)
├── router.dart               # GoRouter route definitions + auth redirect
├── models/                   # Immutable data classes with fromJson/toJson
├── repositories/             # Firestore CRUD via FirestoreService (Repository Pattern)
├── services/                 # Business logic & external service wrappers
│   ├── firestore_service.dart    # Generic Firestore CRUD abstraction
│   ├── auth_service.dart         # Firebase Auth wrapper
│   ├── fcm_service.dart          # Firebase Cloud Messaging wrapper
│   ├── sm2_algorithm.dart        # SM2 spaced repetition algorithm
│   ├── study_timer_service.dart  # Stopwatch with stream
│   ├── review_service.dart       # Review processing with SM2
│   ├── reward_service.dart       # EXP/coin calculation
│   ├── building_service.dart     # Building upgrade logic
│   └── notification_service.dart # Notification scheduling
├── viewmodels/               # ChangeNotifier ViewModels (Riverpod providers)
└── screens/                  # UI screens (ConsumerStatefulWidget)
```

## 3-Layer Architecture

### Presentation Layer (screens/ + viewmodels/)
- Screens are Flutter widgets that observe ViewModels via Riverpod
- ViewModels extend ChangeNotifier and orchestrate user actions

### Business Logic Layer (services/)
- Pure business logic (SM2Algorithm, RewardService, BuildingService)
- No direct Firestore access — delegates to repositories
- StudyTimerService manages the timer independently of UI

### Data Access Layer (repositories/ + models/)
- Repositories encapsulate all Firestore operations
- All repositories receive FirestoreService via constructor injection (testable)
- Models are immutable Dart classes with Firestore Timestamp serialization

## Common Commands

```bash
# Run development server
flutter run -d web

# Build for production
flutter build web

# Analyze code
flutter analyze

# Get dependencies
flutter pub get

# Configure Firebase (first time only)
flutterfire configure
```

## Commit Rules

All commit messages follow **Conventional Commits** format (English):

- `feat:` — new feature
- `fix:` — bug fix
- `refactor:` — refactoring
- `docs:` — documentation changes
- `chore:` — maintenance/other

Examples:
```
feat: add user authentication with Firebase Auth
feat: implement SM2 algorithm for review scheduling
fix: correct coin deduction logic in BuildingViewModel
docs: add CLAUDE.md and README
```
