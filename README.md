# Study City

A gamified study tracking web application built with Flutter. Students track study sessions, review learned material with spaced repetition (SM2 algorithm), and earn rewards to build and upgrade their virtual city.

## Features

- **Study Timer** — Track study sessions per subject with a real-time timer
- **Spaced Repetition** — SM2-based review scheduling (difficulty ratings adjust intervals)
- **Reward System** — Earn EXP and coins from studying and completing reviews
- **City Building** — Spend coins to upgrade 5 buildings (Library, Cafeteria, Gym, Art Room, Science Lab)
- **Statistics** — Bar charts (daily study time) and pie charts (subject breakdown) with period filtering
- **Subject Management** — Create subjects with custom emoji icons and colors
- **Authentication** — Email/password sign-up and sign-in with Firebase Auth

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter Web (Dart) |
| Backend | Firebase (Auth, Firestore, Cloud Messaging) |
| State Management | flutter_riverpod (ChangeNotifierProvider) |
| Routing | go_router (declarative, auth redirect) |
| Charts | fl_chart (BarChart, PieChart) |
| Architecture | 3-Layer (Presentation / Business Logic / Data Access) |

## Architecture

```
Presentation Layer    →  screens/ (UI) + viewmodels/ (ChangeNotifier)
Business Logic Layer  →  services/ (SM2, Timer, Reward, Building)
Data Access Layer     →  repositories/ (Firestore CRUD) + models/ (immutable DTOs)
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.x or later)
- Firebase project with Firestore, Auth, and Cloud Messaging enabled
- Node.js (for Firebase CLI)

### 1. Clone the repository

```bash
git clone https://github.com/joeokinaga/study_city.git
cd study_city
```

### 2. Configure Firebase

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` with your project credentials.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the application

```bash
flutter run -d web
```

### 5. Build for production

```bash
flutter build web
```

## Project Structure

```
lib/
├── main.dart              # Entry point (Firebase init + Riverpod)
├── router.dart            # GoRouter routes + auth guard
├── models/                # Data classes (User, StudySession, ReviewItem, etc.)
├── repositories/          # Firestore data access (Repository Pattern)
├── services/              # Business logic + Firebase service wrappers
├── viewmodels/            # ChangeNotifier state management
└── screens/               # UI screens
    ├── login_screen.dart
    ├── home_screen.dart
    ├── timer_screen.dart
    ├── review_screen.dart
    ├── progress_screen.dart
    ├── stats_screen.dart
    └── subject_management_screen.dart
```

## Documentation

- [`docs/TECH_STACK.md`](docs/TECH_STACK.md) — Technology choices and tradeoffs
- [`docs/DESIGN.md`](docs/DESIGN.md) — Architectural decisions and rationale

## License

This project is part of an academic thesis.
