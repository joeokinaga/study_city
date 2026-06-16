# Study City

> A gamified web application for learning progress tracking and spaced repetition management, built with Flutter and Firebase.

**Live demo:** https://study-city.web.app

---

## What Is Study City?

Study City is a browser-based study companion that solves three problems common to independent learners:

| Problem | What Study City does |
|---|---|
| **Memory decay** — retention drops by more than half within 24 hours of learning (Ebbinghaus, 1885) | Schedules flashcard reviews automatically using the SM2 spaced repetition algorithm |
| **Low motivation** — without external deadlines, the study habit often collapses | Awards EXP and coins for every completed session; coins are spent to build and upgrade a personal virtual city |
| **Fragmented tooling** — timer apps, flashcard apps, and progress trackers are separate products | Combines all three in one loop: Study → Earn → Build → Review |

The core user flow looks like this:

```
[Start timer] → [Study] → [Stop timer]
      ↓
[Earn EXP + coins]
      ↓
[Optionally add review flashcards for today's material]
      ↓
[Spend coins to expand your city]
      ↓
[Get notified when reviews are due] → [Rate cards: Hard / Good / Easy]
      ↓
[SM2 reschedules each card automatically]
```

---

## Key Features

### Study Timer
- Select a subject (or create one inline) and start a stopwatch
- Wake lock prevents the screen from sleeping mid-session
- Sessions shorter than one minute are not recorded
- Rewards on stop: **duration × 10 EXP**, **duration × 5 coins**

### SM2 Spaced Repetition
- Based on the SuperMemo 2 algorithm (Wozniak, 1990)
- After each review, the user rates their recall as **Hard**, **Good**, or **Easy**
- The algorithm adjusts the next review date and an *ease factor* (EF) per card:

  ```
  EF′ = EF + (0.1 − (5 − q) × (0.08 + (5 − q) × 0.02))   with EF′ ≥ 1.3
  ```

  Where `q` is 0 (Hard), 3 (Good), or 5 (Easy).
- Interval schedule: 1 day → 6 days → `⌈previous × EF′⌉` days
- Reward per review: **20 EXP + 10 coins**

### Isometric City
- 15 × 15 diamond-grid canvas (225 tiles)
- 32 building types with prices ranging from 300 to 5,000 coins
- Three footprint sizes: 1×1, 1×2, and 2×2 tiles
- Up to 5 upgrade levels per building; buildings scale visually with each upgrade
- Depth sorting ensures correct overlap rendering

### Progress Dashboard
- Weekly study goal — progress bar against a user-set target (1–112 hours)
- Review completion — needed vs. completed reviews this week
- Forgetting risk panel — classifies each review item as *Overdue*, *Due Soon*, or *Safe*
- 52-week heatmap — daily activity colored by study duration

### Statistics Screen
- Time period selector: Week · Month · Year · All Time
- Daily bar chart (minutes per day, adaptive axis labels)
- Subject pie chart (time split by subject with color-coded legend)
- Summary cards showing total study time and active study days

---

## Technology Stack

| Technology | Role |
|---|---|
| **Flutter / Dart** | Cross-platform UI framework (compiled to web) |
| **Firebase Auth** | Email and password authentication |
| **Cloud Firestore** | Real-time NoSQL cloud database |
| **Firebase Cloud Messaging** | Browser notification reminders for due reviews |
| **flutter_riverpod** | Reactive state management (`ChangeNotifierProvider`) |
| **go_router** | Declarative routing with authentication redirect guard |
| **fl_chart** | Bar charts and pie charts for the statistics screen |
| **wakelock_plus** | Prevents screen sleep during active study sessions |
| **intl** | Date and number formatting |

---

## Architecture

Study City follows a **three-layer clean architecture** to keep UI, logic, and data independent and testable without a live network connection.

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer    screens/ + viewmodels/               │
│  Flutter widgets observe ViewModels via Riverpod providers  │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer  services/                            │
│  SM2, rewards, buildings — no direct Firestore calls        │
├─────────────────────────────────────────────────────────────┤
│  Data Access Layer     repositories/ + models/              │
│  Firestore CRUD encapsulated; models are immutable DTOs     │
└─────────────────────────────────────────────────────────────┘
                         ↕ Firebase (Auth + Firestore + FCM)
```

All repositories receive a `FirestoreService` instance via constructor injection, making them replaceable with fakes in unit tests.

---

## Project Structure

```
lib/
├── main.dart                    # Firebase init + ProviderScope entry point
├── router.dart                  # GoRouter definitions + auth redirect
│
├── models/                      # Immutable data classes with fromJson / toJson
│   ├── user.dart
│   ├── study_session.dart
│   ├── review_item.dart
│   ├── building.dart
│   ├── subject.dart
│   └── ...
│
├── repositories/                # Firestore CRUD (Repository Pattern)
│
├── services/                    # Business logic + external service wrappers
│   ├── sm2_algorithm.dart       # SuperMemo 2 interval calculation
│   ├── study_timer_service.dart # Stopwatch backed by a Dart Stream
│   ├── review_service.dart      # Review processing with SM2
│   ├── reward_service.dart      # EXP and coin calculation
│   ├── building_service.dart    # Purchase, upgrade, placement logic
│   ├── auth_service.dart        # Firebase Auth wrapper
│   ├── firestore_service.dart   # Generic CRUD abstraction
│   ├── fcm_service.dart         # Firebase Cloud Messaging wrapper
│   └── notification_service.dart
│
├── viewmodels/                  # ChangeNotifier ViewModels (Riverpod)
│
└── screens/                     # UI screens (ConsumerStatefulWidget)
    ├── login_screen.dart
    ├── home_screen.dart         # City grid + navigation
    ├── timer_screen.dart
    ├── review_screen.dart
    ├── building_screen.dart
    ├── progress_screen.dart
    ├── stats_screen.dart
    └── subject_management_screen.dart

test/
├── sm2_algorithm_test.dart      # 17 unit tests
├── review_service_test.dart     # 18 unit tests
├── building_service_test.dart   # 24 unit tests
├── building_model_test.dart     # 15 unit tests
└── reward_service_test.dart     # 9 unit tests
```

---

## Testing

### Unit Tests

83 unit tests cover the core business logic. None require a live Firebase connection.

```bash
flutter test
```

| File | Tests | Covers |
|---|---|---|
| `sm2_algorithm_test.dart` | 15 | EF formula, interval schedule, boundary values |
| `building_service_test.dart` | 24 | Purchase validation, upgrade cost, placement |
| `review_service_test.dart` | 18 | SM2 integration, reward calculation on review |
| `building_model_test.dart` | 15 | Model serialization, null safety |
| `reward_service_test.dart` | 11 | EXP and coin formulas for sessions and reviews |

### Manual End-to-End Testing

26 scenarios verified manually in Chrome on macOS, covering:
Authentication · Timer · Subject management · Review flow · City building · Progress dashboard · Statistics

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x or later
- A [Firebase project](https://console.firebase.google.com/) with **Authentication**, **Cloud Firestore**, and **Cloud Messaging** enabled
- Node.js (for the Firebase CLI)

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

This generates `lib/firebase_options.dart` with your project credentials. This file is not committed to version control — each developer runs `flutterfire configure` once for their own Firebase project.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run locally

```bash
flutter run -d web
```

The application opens in your default browser at `http://localhost:XXXX`.

### 5. Build for production

```bash
flutter build web
firebase deploy
```

---

## Firestore Security Rules

All Firestore collections are scoped to the authenticated user's `userId`. A user can only read and write their own documents. The rules are defined in [`firestore.rules`](firestore.rules).

---

## Background

Study City was developed as a BSc thesis project at the **Faculty of Informatics, Eötvös Loránd University** (Budapest, 2026), under the supervision of **Dr. Chaman Verma** (Department of Media and Educational Technology).

Thesis title: *A Gamified Web Application for Learning Progress Tracking and Spaced Repetition Management Using Flutter and Firebase*

---

## License

This project is part of an academic thesis and is not licensed for commercial redistribution.

---

---

# Study City（日本語版）

> Flutter と Firebase で構築された、学習進捗管理と間隔反復学習のためのゲーミフィケーション Web アプリケーション。

**ライブデモ:** https://study-city.web.app

---

## Study City とは？

Study City は、自習する学習者が抱える3つの問題を解決するブラウザベースの学習支援アプリです。

| 問題 | Study City の対応 |
|---|---|
| **記憶の忘却** — 学習後24時間以内に記憶の半分以上が失われる（エビングハウス, 1885） | SM2 間隔反復アルゴリズムを使って、フラッシュカードの復習日程を自動スケジューリング |
| **モチベーション低下** — 締め切りや評価がないと学習習慣が崩れやすい | 学習セッション完了ごとに EXP とコインを付与。コインで仮想都市の建物を購入・アップグレード |
| **ツールの分散** — タイマー・フラッシュカード・進捗管理が別々のアプリに分かれている | 3つを1つのループに統合：学習 → 報酬獲得 → 都市建設 → 復習 |

コアとなるユーザーフローは以下の通りです：

```
[タイマー開始] → [学習] → [タイマー停止]
      ↓
[EXP + コイン獲得]
      ↓
[今日の学習内容を復習フラッシュカードとして追加（任意）]
      ↓
[コインを使って都市を拡張]
      ↓
[復習期限が来たら通知] → [カードを評価：難しい / 普通 / 簡単]
      ↓
[SM2 が次の復習日を自動スケジューリング]
```

---

## 主な機能

### 学習タイマー
- 科目を選択（またはインラインで新規作成）してストップウォッチを開始
- ウェイクロックにより、学習中に画面がスリープするのを防止
- 1分未満のセッションは記録されない
- 停止時の報酬：**経過時間（分）× 10 EXP**、**経過時間（分）× 5 コイン**

### SM2 間隔反復
- SuperMemo 2 アルゴリズム（Wozniak, 1990）に基づく
- 各復習後、ユーザーは記憶の定着度を **難しい**・**普通**・**簡単** で評価
- アルゴリズムがカードごとに次回の復習日と*容易性係数（EF）*を調整：

  ```
  EF′ = EF + (0.1 − (5 − q) × (0.08 + (5 − q) × 0.02))   EF′ ≥ 1.3
  ```

  `q` は 0（難しい）、3（普通）、5（簡単）。
- 復習間隔：1日 → 6日 → `⌈前回の間隔 × EF′⌉` 日
- 復習1回あたりの報酬：**20 EXP + 10 コイン**

### アイソメトリック都市
- 15 × 15 のダイヤモンドグリッドキャンバス（225 タイル）
- 300 〜 5,000 コインの価格帯にわたる 32 種類の建物
- 3つの建物サイズ：1×1・1×2・2×2 タイル
- 建物ごとに最大5段階のアップグレード；アップグレードに応じて見た目が変化
- 重なりが正しく表示されるよう深度ソート処理を実装

### 進捗ダッシュボード
- 週間学習目標 — ユーザー設定の目標時間（1〜112時間）に対する進捗バー
- 復習完了状況 — 今週の必要復習数と完了数の比較
- 忘却リスクパネル — 各復習カードを *期限切れ*・*もうすぐ期限*・*安全* に分類
- 52週間ヒートマップ — 学習時間に応じた色で毎日の活動を表示

### 統計画面
- 期間セレクター：週 · 月 · 年 · 全期間
- 日別棒グラフ（1日あたりの学習時間、軸ラベルが自動調整）
- 科目別円グラフ（科目ごとの学習時間の割合をカラーコードで表示）
- 合計学習時間と学習日数のサマリーカード

---

## 技術スタック

| 技術 | 役割 |
|---|---|
| **Flutter / Dart** | クロスプラットフォーム UI フレームワーク（Web にコンパイル） |
| **Firebase Auth** | メールアドレスとパスワードによる認証 |
| **Cloud Firestore** | リアルタイム NoSQL クラウドデータベース |
| **Firebase Cloud Messaging** | 復習期限のブラウザ通知リマインダー |
| **flutter_riverpod** | リアクティブな状態管理（`ChangeNotifierProvider`） |
| **go_router** | 認証リダイレクトガード付きの宣言的ルーティング |
| **fl_chart** | 統計画面の棒グラフと円グラフ |
| **wakelock_plus** | 学習セッション中の画面スリープを防止 |
| **intl** | 日付と数値のフォーマット |

---

## アーキテクチャ

Study City は、UI・ロジック・データを独立させ、ネットワーク接続なしでテストできるよう **3層クリーンアーキテクチャ** を採用しています。

```
┌─────────────────────────────────────────────────────────────┐
│  プレゼンテーション層   screens/ + viewmodels/              │
│  Flutter ウィジェットが Riverpod で ViewModel を監視        │
├─────────────────────────────────────────────────────────────┤
│  ビジネスロジック層    services/                            │
│  SM2・報酬・建物ロジック — Firestore に直接アクセスしない   │
├─────────────────────────────────────────────────────────────┤
│  データアクセス層      repositories/ + models/              │
│  Firestore CRUD をカプセル化；モデルは不変 DTO              │
└─────────────────────────────────────────────────────────────┘
                    ↕ Firebase (Auth + Firestore + FCM)
```

すべてのリポジトリはコンストラクタインジェクションで `FirestoreService` を受け取るため、ユニットテストではフェイク実装に差し替えることができます。

---

## プロジェクト構成

```
lib/
├── main.dart                    # Firebase 初期化 + ProviderScope エントリポイント
├── router.dart                  # GoRouter の定義 + 認証リダイレクト
│
├── models/                      # fromJson / toJson を持つ不変データクラス
│   ├── user.dart
│   ├── study_session.dart
│   ├── review_item.dart
│   ├── building.dart
│   ├── subject.dart
│   └── ...
│
├── repositories/                # Firestore CRUD（リポジトリパターン）
│
├── services/                    # ビジネスロジック + 外部サービスラッパー
│   ├── sm2_algorithm.dart       # SuperMemo 2 間隔計算
│   ├── study_timer_service.dart # Dart Stream を使ったストップウォッチ
│   ├── review_service.dart      # SM2 を使った復習処理
│   ├── reward_service.dart      # EXP とコインの計算
│   ├── building_service.dart    # 購入・アップグレード・配置ロジック
│   ├── auth_service.dart        # Firebase Auth ラッパー
│   ├── firestore_service.dart   # 汎用 CRUD 抽象化
│   ├── fcm_service.dart         # Firebase Cloud Messaging ラッパー
│   └── notification_service.dart
│
├── viewmodels/                  # ChangeNotifier ViewModel（Riverpod）
│
└── screens/                     # UI 画面（ConsumerStatefulWidget）
    ├── login_screen.dart
    ├── home_screen.dart         # 都市グリッド + ナビゲーション
    ├── timer_screen.dart
    ├── review_screen.dart
    ├── building_screen.dart
    ├── progress_screen.dart
    ├── stats_screen.dart
    └── subject_management_screen.dart

test/
├── sm2_algorithm_test.dart      # 17 ユニットテスト
├── review_service_test.dart     # 18 ユニットテスト
├── building_service_test.dart   # 24 ユニットテスト
├── building_model_test.dart     # 15 ユニットテスト
└── reward_service_test.dart     # 9 ユニットテスト
```

---

## テスト

### ユニットテスト

コアビジネスロジックをカバーする 83 件のユニットテスト。Firebase への接続は不要です。

```bash
flutter test
```

| ファイル | テスト数 | カバー範囲 |
|---|---|---|
| `sm2_algorithm_test.dart` | 15 | EF の計算式、間隔スケジュール、境界値 |
| `building_service_test.dart` | 24 | 購入バリデーション、アップグレードコスト、配置 |
| `review_service_test.dart` | 18 | SM2 との統合、復習時の報酬計算 |
| `building_model_test.dart` | 15 | モデルのシリアライズ、null 安全性 |
| `reward_service_test.dart` | 11 | セッション・復習の EXP とコインの計算式 |

### 手動エンドツーエンドテスト

macOS の Chrome で 26 シナリオを手動検証：
認証 · タイマー · 科目管理 · 復習フロー · 都市建設 · 進捗ダッシュボード · 統計

---

## セットアップ手順

### 前提条件

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x 以降
- **Authentication**・**Cloud Firestore**・**Cloud Messaging** を有効化した [Firebase プロジェクト](https://console.firebase.google.com/)
- Node.js（Firebase CLI 用）

### 1. リポジトリをクローン

```bash
git clone https://github.com/joeokinaga/study_city.git
cd study_city
```

### 2. Firebase を設定

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

これにより `lib/firebase_options.dart` がプロジェクトの認証情報を含む形で生成されます。このファイルはバージョン管理にコミットされていないため、各開発者が自分の Firebase プロジェクト向けに一度 `flutterfire configure` を実行する必要があります。

### 3. 依存パッケージをインストール

```bash
flutter pub get
```

### 4. ローカルで実行

```bash
flutter run -d web
```

デフォルトブラウザで `http://localhost:XXXX` が開きます。

### 5. プロダクションビルド

```bash
flutter build web
firebase deploy
```

---

## Firestore セキュリティルール

すべての Firestore コレクションは認証済みユーザーの `userId` にスコープされています。ユーザーは自分のドキュメントのみ読み書き可能です。ルールは [`firestore.rules`](firestore.rules) に定義されています。

---

## 背景

Study City は、**エトヴェシュ・ロラーンド大学（ブダペスト）情報学部**（2026年）の学士論文プロジェクトとして、**Dr. Chaman Verma**（メディア・教育技術学科）の指導のもとで開発されました。

論文タイトル：*A Gamified Web Application for Learning Progress Tracking and Spaced Repetition Management Using Flutter and Firebase*

---

## ライセンス

このプロジェクトは学術論文の一部であり、商業的な再配布は認められていません。
