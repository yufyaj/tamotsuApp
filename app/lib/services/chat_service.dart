import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tamotsu/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart'; // WebSocket用のパッケージをインポート
import 'dart:io'; // 追加: Fileを使用するためのインポート

class ChatService {
  late WebSocketChannel _channel;
  final String _baseUrl;
  final String _socketUrl;
  final AuthService _authService;

  ChatService({required String baseUrl, required String socketUrl, required AuthService authService}) 
  : _baseUrl = baseUrl, _socketUrl = socketUrl, _authService = authService;

  // WebSocket接続を確立するメソッド
  Future<void> connect() async {
    final verifyResult = await _authService.verifyAccessTokenAutoRefresh();
    if (!verifyResult) { throw Exception('Verificate accessToken error.'); }

    final token = await _authService.getStoredAccessToken();
    if (token == null) {
      throw Exception('Token not found');
    }
    _channel = WebSocketChannel.connect(
      Uri.parse(_socketUrl + '?token=' + token)
    );
  }

  // メッセージを送信するメソッド
  Future<void> sendMessage(String chatId, String message) async {
    final verifyResult = await _authService.verifyAccessTokenAutoRefresh();
    if (!verifyResult) { throw Exception('Verificate accessToken error.'); }

    final token = await _authService.getStoredAccessToken();
    if (token == null) {
      throw Exception('Token not found');
    }
    final messageData = json.encode({
      'action': 'sendmessage',
      'chat_id': chatId,
      'message': message,
      'token': token
    });
    _channel.sink.add(messageData);
  }

  // 画像を送信するメソッド
  Future<Map<String, dynamic>> sendImage(String chatId, String imagePath) async {
    final verifyResult = await _authService.verifyAccessTokenAutoRefresh();
    if (!verifyResult) { throw Exception('Verificate accessToken error.'); }

    final token = await _authService.getStoredAccessToken();
    if (token == null) {
      throw Exception('Token not found');
    }
    
    try {
      // 画像をbase64エンコード
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/sendImage'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'image': base64Image,
          'chat_id': chatId,
        })
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to sendImage');
      }

      return json.decode(response.body);
    } catch (error) {
      print(error);
      throw Exception('Failed to sendImage');
    }
  }

  // 画像を保存するメソッド
  Future<Map<String, dynamic>> saveImage(String imagePath) async {
    try {
      // 画像をbase64エンコード
      final bytes = await File(imagePath).readAsBytes();
      final directory = await getApplicationDocumentsDirectory();

      // オリジナルサイズの画像を保存
      final saveOriginalImagePath = '${directory.path}/image_original_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saveOriginalImageFile = File(saveOriginalImagePath);
      await saveOriginalImageFile.writeAsBytes(bytes);

      // 圧縮した画像を保存
      final compressedBytes = await compressImage(saveOriginalImagePath); // 画像を圧縮する処理
      final saveCompressedImagePath = '${directory.path}/image_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saveCompressedImageFile = File(saveCompressedImagePath);
      await saveCompressedImageFile.writeAsBytes(compressedBytes as List<int>);

      return {
        "originalPath": saveOriginalImagePath,
        "compressedPath": saveCompressedImagePath
      };
    } catch (error) {
      print(error);
      throw Exception('Failed to saveImage');
    }
  }

  Future<Uint8List?> compressImage(String path) async {
    final result = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: 1000,
      minHeight: 1000,
      quality: 94,
      rotate: 90,
    );
    return result;
  }

  // メッセージを受信するストリーム
  Stream get messages => _channel.stream;

  // WebSocket接続を切断するメソッド
  void disconnect() {
    _channel.sink.close();
  }

  // チャット領域を作るメソッド
  Future<void> createChat(String nutritionistId) async {
    final verifyResult = await _authService.verifyAccessTokenAutoRefresh();
    if (!verifyResult) { throw Exception('Verificate accessToken error.'); }

    final token = await _authService.getStoredAccessToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/chat/createChat'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'nutritionistId': nutritionistId
      })
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create chat');
    }
  }

  // チャット領域を取得するメソッド
  Future<List<Map<String, dynamic>>> getJoinChatList() async {
    final verifyResult = await _authService.verifyAccessTokenAutoRefresh();
    if (!verifyResult) { throw Exception('Verificate accessToken error.'); }

    final token = await _authService.getStoredAccessToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/chat/listJoinChat'),
      headers: {
        'Authorization': 'Bearer $token',
      }
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get chat list');
    }

    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['chats']);
  }
}