# Design Decisions

English | [日本語](DESIGN.ja.md)

## 3-Layer Architecture

The app is split into three layers: Presentation (screens + viewmodels), Business Logic (services), and Data Access (repositories + models).

The main constraint this enforces: services never import Firestore directly, and screens never import repositories directly. This kept unit tests fast — the SM2 algorithm, reward calculation, and building upgrade logic are all pure Dart with no Firebase dependency.

## Repository Pattern with FirestoreService Injection

All repositories receive a `FirestoreService` instance through their constructor rather than creating one internally. This means tests can substitute a fake implementation without mocking the Firebase SDK itself.

`FirestoreService` is a thin wrapper around Firestore's collection/document API. It exists to give repositories a stable interface that can be tested against, not to add business logic.

## Firestore Security Rules Scoped to userId

Each collection rule checks `request.auth.uid == userId` on the document being accessed. The alternative — a single `allow read, write: if request.auth != null` — would let any authenticated user read any other user's data. The per-document check closes that gap with minimal added complexity.

## SM2 Algorithm as a Pure Service

The SM2 spaced-repetition logic lives in `sm2_algorithm.dart` as a stateless class with no dependencies. Input: current item schedule, user rating, and the current date. Output: updated schedule (next review date, interval, ease factor). This made the algorithm straightforward to unit-test exhaustively across all rating/interval combinations without touching Firestore or the widget tree.

## Subject Display Constants on the Model

`iconOptions`, `colorOptions`, and `parseColor` are static members of `Subject` rather than local constants in each screen. The subject icon and color are properties of the `Subject` model — the valid values and their parsing belong with the data, not with any particular UI that happens to display them. This eliminated duplication between `TimerScreen` and `SubjectManagementScreen`.

## Dev Auto-Login Behind a Flag

A `kDevMode` constant in `dev_config.dart` controls whether the app skips the login screen and signs in automatically. The flag is set to `false` before any production build. This avoids accidentally shipping an app that bypasses authentication, while keeping the development feedback loop fast.
