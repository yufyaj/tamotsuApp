import 'dart:io';

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:lecle_flutter_absolute_path/lecle_flutter_absolute_path.dart';
import 'package:provider/provider.dart';
import 'package:tamotsu/viewmodels/chat_view_model.dart';
import 'package:multi_image_picker_plus/multi_image_picker_plus.dart';

@RoutePage()
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Asset> images = <Asset>[];
  String _error = 'No Error Dectected';

  Future<void> _loadAssets() async {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    List<Asset> resultList = <Asset>[];
    String error = 'No Error Dectected';
    
    const AlbumSetting albumSetting = AlbumSetting(
      fetchResults: {
        PHFetchResult(
          type: PHAssetCollectionType.smartAlbum,
          subtype: PHAssetCollectionSubtype.smartAlbumUserLibrary,
        ),
        PHFetchResult(
          type: PHAssetCollectionType.smartAlbum,
          subtype: PHAssetCollectionSubtype.smartAlbumFavorites,
        ),
        PHFetchResult(
          type: PHAssetCollectionType.album,
          subtype: PHAssetCollectionSubtype.albumRegular,
        ),
        PHFetchResult(
          type: PHAssetCollectionType.smartAlbum,
          subtype: PHAssetCollectionSubtype.smartAlbumSelfPortraits,
        ),
        PHFetchResult(
          type: PHAssetCollectionType.smartAlbum,
          subtype: PHAssetCollectionSubtype.smartAlbumPanoramas,
        ),
        PHFetchResult(
          type: PHAssetCollectionType.smartAlbum,
          subtype: PHAssetCollectionSubtype.smartAlbumVideos,
        ),
      },
    );
    const SelectionSetting selectionSetting = SelectionSetting(
      min: 0,
      max: 3,
      unselectOnReachingMax: true,
    );
    const DismissSetting dismissSetting = DismissSetting(
      enabled: true,
      allowSwipe: true,
    );
    final ThemeSetting themeSetting = ThemeSetting(
      backgroundColor: Colors.white,
      selectionFillColor: Colors.blue,
      selectionStrokeColor: Colors.blue,
      previewSubtitleAttributes: const TitleAttribute(fontSize: 12.0),
      previewTitleAttributes: TitleAttribute(
        foregroundColor: Colors.blue,
      ),
      albumTitleAttributes: TitleAttribute(
        foregroundColor: Colors.blue,
      ),
    );
    const ListSetting listSetting = ListSetting(
      spacing: 5.0,
      cellsPerRow: 4,
    );
    const AssetsSetting assetsSetting = AssetsSetting(
      // Set to allow pick videos.
      supportedMediaTypes: {MediaTypes.video, MediaTypes.image},
    );
    final CupertinoSettings iosSettings = CupertinoSettings(
      fetch: const FetchSetting(album: albumSetting, assets: assetsSetting),
      theme: themeSetting,
      selection: selectionSetting,
      dismiss: dismissSetting,
      list: listSetting,
    );

    try {
      resultList = await MultiImagePicker.pickImages(
        selectedAssets: images,
        iosOptions: IOSOptions(
          doneButton:
              UIBarButtonItem(title: 'Confirm', tintColor: Colors.green), // 完了ボタンの色を緑に変更
          cancelButton:
              UIBarButtonItem(title: 'Cancel', tintColor: Colors.green), // 戻るボタンの色を緑に変更
          albumButtonColor: colorScheme.primary,
          settings: iosSettings,
        ),
        androidOptions: AndroidOptions(
          actionBarColor: Colors.green,
          actionBarTitleColor: colorScheme.surface, // チェックボタンの色を緑に変更
          statusBarColor: colorScheme.surface,
          actionBarTitle: "送信する写真を選択",
          allViewTitle: "すべての写真",
          useDetailsView: false,
          selectCircleStrokeColor: colorScheme.primary,
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
      _error = error;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
      chatViewModel.fetchMessages('C0000004').then((_) {
        // メッセージ取得後に一番下までスクロール
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });

    _scrollController.addListener(() {
    if (_scrollController.position.atEdge) {
      // TODO: ここの更新仕様は要検討
      if (_scrollController.position.pixels <= 90) {
        // 一番上にスクロールしたとき
        final chatViewModel = Provider.of<ChatViewModel>(context, listen: false);
        chatViewModel.fetchMessages('C0000004', loadMore: true);
      }
    }
  });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatViewModel = Provider.of<ChatViewModel>(context, listen: true);

    return ChangeNotifierProvider(
      create: (_) => chatViewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text('チャット相談'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: chatViewModel.messages.length,
                itemBuilder: (context, index) {
                  final message = chatViewModel.messages[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: message['contentType'] == 'image' 
                        ? Image.file(File(message['imagePathSmall'])) // 画像を表示
                        : Text(message['contentName']), // メッセージを表示
                    subtitle: Text(message['sendedAt']), // 送信日時を表示
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'メッセージを入力',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: () async {
                      await _loadAssets();
                      if (images != null) {
                        images.forEach((image) async {
                          final filePath = await LecleFlutterAbsolutePath.getAbsolutePath(uri: image.identifier);
                          chatViewModel.sendImage("C0000004", filePath!);
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      String message = _textController.text;
                      if (message.isNotEmpty) {
                        await chatViewModel.sendMessage("C0000004", message);
                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        _textController.clear(); // 送信後にテキストフィールドをクリア
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}