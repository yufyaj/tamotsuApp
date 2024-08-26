import 'package:flutter/material.dart'; // FlutterのUIライブラリをインポート
import 'package:tamotsu/services/chat_service.dart';
import 'package:tamotsu/services/database_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService; // ChatServiceのインスタンス
  final DatabaseService _databaseService;

  List<Map<String, dynamic>> _messages = []; // チャットメッセージを保持するリスト
  bool _isConnected = false; // 接続状態を示すフラグ
  bool _isLoading = false; // ローディング状態を示すフラグ
  bool get isLoading => _isLoading; // ローディング状態を取得するゲッター
  int _currentPage = 0;
  final int _pageSize = 10;

  // コンストラクタでChatServiceのインスタンスを受け取る
  ChatViewModel({required ChatService chatService, required DatabaseService databaseService})
   : _chatService = chatService, _databaseService = databaseService;

  // 接続メソッド
  Future<void> connect() async {
    try {
      await _chatService.connect(); // WebSocket接続を確立

      _isConnected = true;
      notifyListeners(); // リスナーに通知

      // メッセージを受信するストリームを監視
      _chatService.messages.listen((body) {
        print('Received message: $body');
        _messages.add(body); // 受信したメッセージをリストに追加
        notifyListeners(); // リスナーに通知
      });
    } catch (error) {
      rethrow;
    }
  }

  // メッセージを取得するゲッター
  List<Map<String, dynamic>> get messages => _messages.reversed.toList();
  // 接続状態を取得するゲッター
  bool get isConnected => _isConnected;

  // メッセージを送信するメソッド
  Future<void> sendMessage(String chatId, String message) async {
    if (_isConnected) {
      try {
        await _chatService.sendMessage(chatId, message); // ChatServiceを使用してメッセージを送信
        await _databaseService.insertMessage(chatId, 'me', 'message', message, '', ''); // メッセージをデータベースに保存
        await fetchMessages(chatId);
      } catch (e) {
        rethrow;
      }
    }
  }

  // 画像を送信するメソッド
  Future<void> sendImage(String chatId, String imagePath) async {
    if (_isConnected) {
      try {
        // 画像を送信する処理
        final response = await _chatService.sendImage(chatId, imagePath);
        final savedPath = await _chatService.saveImage(imagePath);
        await _databaseService.insertMessage(chatId, 'me', 'image', response['fileName'], savedPath['originalPath'], savedPath['compressedPath']); // メッセージをデータベースに保存
      } catch (e) {
        rethrow;
      }
    }
  }

  // チャット内容を取得する
  Future<void> fetchMessages(String chatId, {bool loadMore = false}) async {
    if (!loadMore) {
      _messages = [];
      _currentPage = 0;
    }
    final newMessages = await _databaseService.getMessages(chatId, _currentPage * _pageSize, _pageSize);
    _messages.addAll(newMessages);
    _currentPage++;
    notifyListeners();
  }

  // 接続を切断するメソッド
  void disconnect() {
    _chatService.disconnect(); // ChatServiceを使用して接続を切断
    _isConnected = false;
    notifyListeners(); // リスナーに通知
  }

  // チャット領域を用意するメソッド
  Future<void> createChat(String nutritionistId) async {
    _isLoading = true; // ローディング状態をtrueに設定
    notifyListeners(); // リスナーに通知

    try {
      await _chatService.createChat(nutritionistId);
    } catch (e) {
        rethrow;
    } finally {
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
    }
  }

  // チャットリストを取得するメソッド
  Future<void> getJoinChatList() async {
    _isLoading = true; // ローディング状態をtrueに設定
    notifyListeners(); // リスナーに通知

    try {
      await _chatService.getJoinChatList();
    } catch (e) {
        rethrow;
    } finally {
      _isLoading = false; // ローディング状態をfalseに設定
      notifyListeners(); // リスナーに通知
    }
  }
}