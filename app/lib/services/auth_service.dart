import 'package:http/http.dart' as http; // HTTPリクエストを行うためのパッケージをインポート
import 'dart:convert'; // JSONエンコード/デコードのためのパッケージをインポート
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String baseUrl; // APIのベースURL
  final String accessTokenKey = 'auth_access_token'; // 接続トークンを保存する際のキー
  final String refreshTokenKey = 'auth_refresh_token'; // 更新トークンを保存する際のキー
  final String userTypeKey = 'auth_userType'; // ユーザータイプを保存する際のキー

    // コンストラクタでbaseUrlとauthServiceを受け取る
  AuthService({required this.baseUrl});

  // ログインメソッド
  Future<void> login(String email, String password) async {
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
      final accessToken = json.decode(response.body)['access_token'];
      final refreshToken = json.decode(response.body)['refresh_token'];
      await _storeTokens(accessToken, refreshToken);
      final userType = json.decode(response.body)['userType']; // レスポンスからユーザータイプを取得
      await _storeUserType(userType); // トークンをローカルストレージに保存
      return;
    } else {
      throw Exception('ログインに失敗しました'); // エラーハンドリング
    }
  }

  // ログアウトメソッド
  Future<void> logout() async {
    await _removeTokens(); // ローカルストレージからトークンを削除
  }

  // 保存されたユーザータイプを取得するメソッド
  Future<String?> getStoredUserType() async {
    return await _storage.read(key: userTypeKey);
  }

  // TODO: アクセストークンが期限切れの時に、更新トークンを使って自動更新したい
  // 保存されたアクセストークンを取得するメソッド
  Future<String?> getStoredAccessToken() async {
    return await _storage.read(key: accessTokenKey);
  }

  // 保存された更新トークンを取得するメソッド
  Future<String?> getStoredRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }

  // ユーザータイプを保存するプライベートメソッド
  Future<void> _storeUserType(String userType) async {
    await _storage.write(key: userTypeKey, value: userType);
  }

  // トークンを保存するプライベートメソッド
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: accessTokenKey, value: accessToken);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
  }

  // トークンを削除するプライベートメソッド
  Future<void> _removeTokens() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
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
      return true; // 成功を返す
    } else {
      // TODO: ここのエラー内容が新規登録画面に表示される
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

  // アクセストークンを検証するメソッド
  Future<bool> _verifyAccessToken() async {
    try {
      // アクセストークンの検証ロジック
      final token = await getStoredAccessToken();
      if (token != null) { return false; }

      // ここでHTTPリクエストを送信してトークンを検証
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify-token'),
        headers: {'Authorization': 'Bearer $token'}
      );

      // レスポンスが成功した場合
      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (error) {
      return false;
    }
  }

  // トークンをリフレッシュするメソッド
  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await getStoredRefreshToken();
      if (refreshToken == null) { return false; }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Refresh-Token': refreshToken
        },
      );

      if (response.statusCode == 200) {
        final newAccessToken = json.decode(response.body)['accessToken'];
        final newRefreshToken = json.decode(response.body)['refreshToken'];
        await _storeTokens(newAccessToken, newRefreshToken);
        return true;
      }
      
      return false;
    } catch (error) {
      return false;
    }
  }

  // 認証状態をチェックするメソッド
  Future<bool> verifyAccessTokenAutoRefresh() async {
    try {
      final verifyResult = await _verifyAccessToken();
      if (!verifyResult) {
        final refreshResult = await _refreshAccessToken();
        if (!refreshResult) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
