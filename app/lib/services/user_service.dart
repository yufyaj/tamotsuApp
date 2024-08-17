import 'dart:convert'; // JSONエンコード/デコードのためのパッケージをインポート
import 'package:http/http.dart' as http; // HTTPリクエストを行うためのパッケージをインポート
import 'auth_service.dart'; // AuthServiceをインポート

class UserService {
  final String baseUrl; // APIのベースURL
  final AuthService authService; // AuthServiceのインスタンス

  // コンストラクタでbaseUrlとauthServiceを受け取る
  UserService({required this.baseUrl, required this.authService});

  // ユーザープロフィールを取得するメソッド
  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await authService.getStoredToken(); // 保存されたトークンを取得
    if (token == null) {
      throw Exception('Token not found'); // トークンが見つからない場合のエラーハンドリング
    }

    // GETリクエストを送信してユーザープロフィールを取得
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: {
        'Authorization': 'Bearer $token', // リクエストヘッダーにトークンを設定
      },
    );

    // レスポンスが成功した場合
    if (response.statusCode == 200) {
      return json.decode(response.body); // レスポンスボディをデコードして返す
    } else {
      throw Exception('Failed to load profile'); // エラーハンドリング
    }
  }

  // ユーザープロフィールを更新するメソッド
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    final token = await authService.getStoredToken(); // 保存されたトークンを取得
    if (token == null) {
      throw Exception('Token not found'); // トークンが見つからない場合のエラーハンドリング
    }

    // PUTリクエストを送信してユーザープロフィールを更新
    final response = await http.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: {
        'Authorization': 'Bearer $token', // リクエストヘッダーにトークンを設定
        'Content-Type': 'application/json', // リクエストヘッダーにContent-Typeを設定
      },
      body: json.encode(profileData), // リクエストボディにプロフィールデータをJSON形式で設定
    );

    // レスポンスが成功した場合
    if (response.statusCode == 200) {
      return json.decode(response.body); // レスポンスボディをデコードして返す
    } else {
      throw Exception('Failed to update profile'); // エラーハンドリング
    }
  }

  // 特定ユーザーの公開プロフィールを取得するメソッド
  Future<Map<String, dynamic>> getUserPublicProfile(String userId) async {
    final token = await authService.getStoredToken(); // 保存されたトークンを取得
    if (token == null) {
      throw Exception('Token not found'); // トークンが見つからない場合のエラーハンドリング
    }

    // GETリクエストを送信して公開プロフィールを取得
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token', // リクエストヘッダーにトークンを設定
      },
    );

    // レスポンスが成功した場合
    if (response.statusCode == 200) {
      return json.decode(response.body); // レスポンスボディをデコードして返す
    } else {
      throw Exception('Failed to load public profile'); // エラーハンドリング
    }
  }

  // 特定ユーザーの公開プロフィールを取得するメソッド
  Future<void> selectNutritionist(String nutritionistId) async {
    final token = await authService.getStoredToken(); // 保存されたトークンを取得
    if (token == null) {
      throw Exception('Token not found'); // トークンが見つからない場合のエラーハンドリング
    }

    // PUTリクエストを送信して
    final response = await http.put(
      Uri.parse('$baseUrl/users/selectNutritionist'),
      headers: {
        'Authorization': 'Bearer $token', // リクエストヘッダーにトークンを設定
      },
      body: json.encode({
        'nutritionistId': nutritionistId,
      }), // リクエストボディに管理栄養士IDをJSON形式で設定
    );

    // レスポンスが成功した場合
    if (response.statusCode == 200) {
      return;
    } else {
      throw Exception('Failed to load public profile'); // エラーハンドリング
    }
  }

}
