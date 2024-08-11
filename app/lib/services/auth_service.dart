import 'package:http/http.dart' as http; // HTTPリクエストを行うためのパッケージをインポート
import 'dart:convert'; // JSONエンコード/デコードのためのパッケージをインポート
import 'package:shared_preferences/shared_preferences.dart'; // ローカルストレージにデータを保存するためのパッケージをインポート

class AuthService {
  final String baseUrl; // APIのベースURL
  final String tokenKey = 'auth_token'; // トークンを保存する際のキー

    // コンストラクタでbaseUrlとauthServiceを受け取る
  AuthService({required this.baseUrl});

  // ログインメソッド
  Future<String> login(String email, String password) async {
    // POSTリクエストを送信してログインを試みる
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'}, // リクエストヘッダーにContent-Typeを設定
      body: json.encode({
        'email': email,
        'password': password,
      }), // リクエストボディにメールアドレスとパスワードをJSON形式で設定
    );

    // レスポンスが成功した場合
    if (response.statusCode == 200) {
      final token = json.decode(response.body)['token']; // レスポンスからトークンを取得
      await _storeToken(token); // トークンをローカルストレージに保存
      return token; // トークンを返す
    } else {
      throw Exception('ログインに失敗しました'); // エラーハンドリング
    }
  }

  // ログアウトメソッド
  Future<void> logout() async {
    await _removeToken(); // ローカルストレージからトークンを削除
  }

  // 保存されたトークンを取得するメソッド
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance(); // SharedPreferencesのインスタンスを取得
    return prefs.getString(tokenKey); // トークンを取得して返す
  }

  // トークンを保存するプライベートメソッド
  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance(); // SharedPreferencesのインスタンスを取得
    await prefs.setString(tokenKey, token); // トークンを保存
  }

  // トークンを削除するプライベートメソッド
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance(); // SharedPreferencesのインスタンスを取得
    await prefs.remove(tokenKey); // トークンを削除
  }

  // ユーザー登録メソッド
  Future<bool> register(String email, String userType) async {
    // POSTリクエストを送信してユーザー登録を試みる
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'}, // リクエストヘッダーにContent-Typeを設定
      body: json.encode({
        'email': email,
        'userType': userType,
      }), // リクエストボディにメールアドレスとユーザータイプをJSON形式で設定
    );

    // レスポンスが成功した場合
    if (response.statusCode == 200) {
      return true; // 成功を返す
    } else {
      throw Exception('登録に失敗しました'); // エラーハンドリング
    }
  }

  // メール認証メソッド
  Future<bool> verifyEmail(String verificationCode, String email, String password) async {
    // POSTリクエストを送信してメール認証を試みる
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-email'),
      headers: {'Content-Type': 'application/json'}, // リクエストヘッダーにContent-Typeを設定
      body: json.encode({
        'email': email,
        'verificationCode': verificationCode,
        'password': password
      }), // リクエストボディにメールアドレス、認証コード、パスワードをJSON形式で設定
    );

    // レスポンスが成功した場合
    if (response.statusCode == 200) {
      final token = json.decode(response.body)['token']; // レスポンスからトークンを取得
      await _storeToken(token); // トークンをローカルストレージに保存
      return true; // 成功を返す
    } else {
      throw Exception('メール認証に失敗しました'); // エラーハンドリング
    }
  }

  // パスワードリセットリクエストメソッド
  Future<bool> resetPassword(String email) async {
    // POSTリクエストを送信してパスワードリセットを試みる
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'}, // リクエストヘッダーにContent-Typeを設定
      body: json.encode({
        'email': email,
      }), // リクエストボディにメールアドレスをJSON形式で設定
    );

    // レスポンスが成功した場合
    if (response.statusCode == 200) {
      return true; // 成功を返す
    } else {
      throw Exception('パスワードリセットリクエストに失敗しました'); // エラーハンドリング
    }
  }
}
