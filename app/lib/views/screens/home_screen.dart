import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // ここにログアウト処理を追加
              // 例: context.read<AuthViewModel>().logout();
              // その後、ログイン画面にナビゲート
              // context.router.replaceAll([LoginRoute()]);
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'ようこそ！',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
