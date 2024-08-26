import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tamotsu/routes/app_router.dart';

@RoutePage()
class UserHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TAMOTSU'),
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 0:
                  // プロフィール編集画面への遷移処理
                  context.router.push(UserProfileEditRoute());
                  break;
                case 1:
                  // ログアウト処理
                  _logout(context);
                  break;
                case 2:
                  // ログアウト処理
                  _logout(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: Text('プロフィール編集'),
              ),
              PopupMenuItem(
                value: 1,
                child: Text('パスワード変更'),
              ),
              PopupMenuItem(
                value: 2,
                child: Text('ログアウト'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'おはようございます, XXXさん!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.line_weight, color: Colors.green),
                title: Text('現在の体重'),
                subtitle: Text(
                  '70 kg',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(Icons.show_chart, color: Colors.green),
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFeatureButton(Icons.restaurant, '食事記録', () {
                  // 食事記録画面への遷移処理
                }),
                _buildFeatureButton(Icons.fitness_center, '体重記録', () {
                  // 体重記録画面への遷移処理
                }),
                _buildFeatureButton(Icons.chat, 'チャット相談', () {
                  // チャット相談画面への遷移処理
                  context.router.push(const ChatRoute());
                }),
                _buildFeatureButton(Icons.videocam, 'ビデオ相談', () {
                  // ビデオ相談画面への遷移処理
                }),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildFeatureButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.green),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 16, color: Colors.green)),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    // ログアウト処理をここに実装
    // 例えば、認証情報をクリアしてログイン画面に遷移するなど
    print('ログアウトしました');
  }
}