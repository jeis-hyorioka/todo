# Flutter ToDoアプリ

Googleログイン・Firestore連携・リスト共有機能付きのマルチプラットフォーム対応ToDoアプリです。

## 主な機能
- Googleアカウントによる認証（Googleログイン／ユーザー名表示／ログアウト）
- FirestoreによるユーザーごとのToDoリスト管理
- 複数リストの作成・切り替え・削除
- タスクの追加・削除・完了状態の切り替え
- 招待機能（ワンタイム8桁英数字の招待コード発行・参加）
- 参加者一覧・リスト設定（タイトル編集/削除/退出）
- サイドメニューでリスト切替・ログアウト
- Web/iOS/Android対応
- モダンなUI（Material3＋Google Fonts／ボトムシートUI／ダイナミックアイランド考慮）

## 技術構成
- Flutter 3.x
- Riverpod（状態管理）
- Firebase Auth（Googleログイン）
- Cloud Firestore
- MVVM＋Repositoryパターン

## ディレクトリ構成例
```
lib/
  main.dart
  todo_list_view_model.dart
  todo_list_repository.dart
  todo_list_selector.dart
  todo_list_settings_page.dart
  todo_view_model.dart
  todo_repository.dart
  invite_view_model.dart
  invite_repository.dart
  invite_code_dialog.dart
  invite_code_issued_dialog.dart
  side_menu.dart
```

## セットアップ
1. Firebaseプロジェクト作成・Web/iOS/Android設定
2. `firebase_options.dart`を生成
3. `flutter pub get` で依存解決
4. 各プラットフォームでビルド・実行

## 注意事項
- Firestoreのセキュリティルール・認証設定を必ずご確認ください
- GoogleログインにはFirebase Authの設定が必要です

## ライセンス
MIT
