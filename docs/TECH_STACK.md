# Tech Stack

English | [日本語](TECH_STACK.ja.md)

## Flutter Web

Chosen because the same codebase targets Web, iOS, and Android. The app currently ships as a web app, but a future mobile release requires no additional framework — unlike React, which would need a separate React Native project for mobile. Dart's strong typing also catches data model bugs (SM2 schedule, EXP/coins) at compile time rather than at runtime.

The tradeoff: Flutter Web has a larger initial bundle size and weaker SEO than React or Vue. Neither is a concern for this app — users are logged in before seeing any content, so SEO does not apply, and the bundle size is acceptable for a tool users return to repeatedly rather than a landing page.

## Firebase

Chosen for the combination of Auth, Firestore, and Cloud Messaging under one SDK. For a solo project, managing a custom backend server would have shifted time away from the core study-loop logic (SM2, rewards, city building). Firestore's real-time streams map naturally to the app's live update requirements (subjects list, review queue).

The tradeoff: Firestore cannot filter by multiple fields without a pre-built composite index. The date-range query in `StudySessionRepository` works around this by fetching all sessions for the user and filtering client-side in Dart. This is acceptable because a single user's session count stays in the hundreds — not a scale where transferring the full set is a problem. A relational database like PostgreSQL would handle this query natively, and would be the right choice if the data grew significantly.

## flutter_riverpod (ChangeNotifierProvider)

Chosen over plain `provider` because Riverpod providers are readable outside of the widget tree — no `BuildContext` required. This means ViewModels have no dependency on Flutter itself, making them straightforward to unit-test: inject a mock repository and verify state transitions with plain Dart, no widget tree needed.

`ChangeNotifier` was kept rather than migrating to `AsyncNotifier` because the app's async operations (Firestore reads/writes) are always triggered by explicit user actions, not on widget mount. The simpler model was sufficient.

## go_router

Chosen for declarative routing with a `redirect` callback. The auth guard lives in one place (`router.dart`) rather than being scattered across individual screens. Deep links and browser back-button behavior work correctly with no extra wiring.

## fl_chart

Chosen for bar and pie chart rendering in the stats screen. Lightweight enough for web and supports the custom styling (color-coded subjects) needed for the study history visualization.

## wakelock_plus

Prevents the screen from sleeping during an active study session. Single-purpose package with a minimal API.
