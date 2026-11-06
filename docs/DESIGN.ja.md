# 設計判断

[English](DESIGN.md) | 日本語

## 3層アーキテクチャ

アプリをPresentation層（screens + viewmodels）・Business Logic層（services）・Data Access層（repositories + models）の3層に分割している。

主な制約：servicesはFirestoreを直接importしない、screensはrepositoriesを直接importしない。これによりユニットテストが高速になる。SM2アルゴリズム・報酬計算・建物アップグレードのロジックはすべてFirebase依存のない純粋なDartコードでテストできる。

## コンストラクタインジェクションによるRepositoryパターン

各リポジトリはFirebaseSDKをモックせずにテストできるよう、`FirestoreService`インスタンスを内部で生成せずコンストラクタで受け取る。

`FirestoreService`はFirestoreのコレクション/ドキュメントAPIの薄いラッパー。ビジネスロジックを持たず、テスト可能な安定したインターフェースを提供することだけが目的。

## ユーザーIDでスコープしたFirestoreセキュリティルール

各コレクションのルールはアクセス対象ドキュメントに対して`request.auth.uid == userId`を検証する。`allow read, write: if request.auth != null`という代替案では認証済みユーザーが他のユーザーのデータを読み書きできてしまう。ドキュメント単位のチェックにより複雑さを最小限に抑えながらその問題を解消している。

## 純粋なサービスとしてのSM2アルゴリズム

SM2間隔反復ロジックは`sm2_algorithm.dart`に依存関係のないステートレスなクラスとして実装している。入力：現在のアイテムスケジュール・ユーザー評価・現在日時。出力：更新されたスケジュール（次回復習日・間隔・難易度係数）。FirestoreやウィジェットツリーなしにすべてのRating/間隔の組み合わせを網羅的にユニットテストできる。

## モデルへのSubject表示定数の集約

`iconOptions`・`colorOptions`・`parseColor`は各画面のローカル定数としてではなく`Subject`の静的メンバーとして定義している。科目のアイコンと色は`Subject`モデルのプロパティであり、有効な値の定義とその解析はデータ側に属する。これにより`TimerScreen`と`SubjectManagementScreen`間の重複を解消した。

## フラグで管理する開発用自動ログイン

`dev_config.dart`の`kDevMode`定数がログイン画面をスキップして自動サインインするかを制御する。本番ビルド前にフラグを`false`に設定する。認証をバイパスするアプリを誤って本番リリースするリスクを防ぎながら、開発時のフィードバックループを高速に保てる。
