import 'package:flutter/material.dart'; // FlutterのUIライブラリをインポート
import 'package:tamotsu/services/user_service.dart'; // UserServiceをインポート

class UserViewModel extends ChangeNotifier {
  final UserService userService; // UserServiceのインスタンス

  // コンストラクタでUserServiceのインスタンスを受け取る
  UserViewModel({required this.userService});

  Map<String, dynamic>? _userProfile; // ユーザープロフィールを保持する変数
  Map<String, dynamic>? get userProfile => _userProfile; // ユーザープロフィールを取得するゲッター

  Map<String, dynamic>? _publicProfile; // 公開プロフィールを保持する変数
  Map<String, dynamic>? get publicProfile => _publicProfile; // 公開プロフィールを取得するゲッター

  bool _isLoading = false; // ローディング状態を示すフラグ
  bool get isLoading => _isLoading; // ローディング状態を取得するゲッター

  // ユーザープロフィールを取得するメソッド
  Future<void> fetchUserProfile() async {
    _isLoading = true; // ローディング状態をtrueに設定
    notifyListeners(); // リスナーに通知

    try {
      _userProfile = await userService.getUserProfile(); // UserServiceを使用してユーザープロフィールを取得
    } catch (e) {
      // エラーハンドリング
    } finally {
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
    }
  }

  // ユーザープロフィールを更新するメソッド
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    _isLoading = true; // ローディング状態をtrueに設定
    notifyListeners(); // リスナーに通知

    try {
      await userService.updateUserProfile(profileData); // UserServiceを使用してユーザープロフィールを更新
      await fetchUserProfile(); // プロフィールデータをリフレッシュ
    } catch (e) {
      // エラーハンドリング
    } finally {
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
    }
  }

  // 特定ユーザーの公開プロフィールを取得するメソッド
  Future<void> fetchUserPublicProfile(String userId) async {
    _isLoading = true; // ローディング状態をtrueに設定
    notifyListeners(); // リスナーに通知

    try {
      _publicProfile = await userService.getUserPublicProfile(userId); // UserServiceを使用して公開プロフィールを取得
    } catch (e) {
      // エラーハンドリング
    } finally {
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
    }
  }
}
