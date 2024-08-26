import 'package:flutter/foundation.dart'; // ChangeNotifierを使用するためのパッケージをインポート
import '../services/auth_service.dart'; // AuthServiceをインポート

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService; // AuthServiceのインスタンス
  bool _isLoading = false; // ローディング状態を示すフラグ
  String? _error; // エラーメッセージを保持する変数

  // コンストラクタでAuthServiceのインスタンスを受け取る
  AuthViewModel({required AuthService authService}) : _authService = authService;

  // ローディング状態を取得するゲッター
  bool get isLoading => _isLoading;

  // エラーメッセージを取得するゲッター
  String? get error => _error;

  // ユーザー登録メソッド
  Future<bool> register(String email, String userType) async {
    _isLoading = true; // ローディング状態をtrueに設定
    _error = null; // エラーメッセージをクリア
    notifyListeners(); // リスナーに通知

    try {
      bool result = await _authService.register(email, userType); // AuthServiceを使用してユーザー登録
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
      return result; // 登録結果を返す
    } catch (e) {
      _error = e.toString(); // エラーメッセージを設定
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
      return false; // エラーの場合はfalseを返す
    }
  }

  // ログインメソッド
  Future<bool> login(String email, String password) async {
    _isLoading = true; // ローディング状態をtrueに設定
    _error = null; // エラーメッセージをクリア
    notifyListeners(); // リスナーに通知

    try {
      await _authService.login(email, password); // AuthServiceを使用してログイン
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
      return true; // ログイン成功の場合はtrueを返す
    } catch (e) {
      _error = e.toString(); // エラーメッセージを設定
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
      return false; // エラーの場合はfalseを返す
    }
  }

  // メール認証メソッド
  Future<bool> verifyEmail(String verificationCode, String email, String password) async {
    _isLoading = true; // ローディング状態をtrueに設定
    _error = null; // エラーメッセージをクリア
    notifyListeners(); // リスナーに通知

    try {
      await _authService.verifyEmail(verificationCode, email, password); // AuthServiceを使用してメール認証
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
      return true; // 認証成功の場合はtrueを返す
    } catch (e) {
      _error = e.toString(); // エラーメッセージを設定
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
      return false; // エラーの場合はfalseを返す
    }
  }

  // ログアウトメソッド
  Future<void> logout() async {
    _isLoading = true; // ローディング状態をtrueに設定
    notifyListeners(); // リスナーに通知

    try {
      await _authService.logout(); // AuthServiceを使用してログアウト
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
    } catch (e) {
      _error = e.toString(); // エラーメッセージを設定
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
    }
  }

  // ユーザータイプをチェックするメソッド
  Future<String?> getAuthUserType() async {
    _isLoading = true; // ローディング状態をtrueに設定
    notifyListeners(); // リスナーに通知

    try {
      final _userType = await _authService.getStoredUserType(); // 保存されたトークンを取得
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
      return _userType;
    } catch (e) {
      _error = e.toString(); // エラーメッセージを設定
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
      return null;
    }
  }
}
