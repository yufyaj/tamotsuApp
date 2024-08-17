import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tamotsu/models/nutritionist.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tamotsu/routes/app_router.dart';
import 'package:tamotsu/viewmodels/user_view_model.dart';

@RoutePage()
class NutritionistDetailScreen extends StatelessWidget {
  final Nutritionist nutritionist;

  const NutritionistDetailScreen({Key? key, required this.nutritionist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nutritionist.name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Hero(
                      tag: 'nutritionist-${nutritionist.nutritionist_id}',
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(nutritionist.imageUrl),
                        onBackgroundImageError: (_, __) => Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(nutritionist.name, style: Theme.of(context).textTheme.headlineSmall),
                  SizedBox(height: 8),
                  Text(nutritionist.introduction),
                  SizedBox(height: 16),
                  Text('得意分野:', style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 8,
                    children: nutritionist.specialties
                        .map((specialty) => Chip(label: Text(specialty)))
                        .toList(),
                  ),
                  SizedBox(height: 16),
                  Text('登録者数: ${nutritionist.registeredUsers}人'),
                  SizedBox(height: 16),
                  Text('対応可能時間:', style: Theme.of(context).textTheme.titleMedium),
                  ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: nutritionist.availableHours.entries.map((entry) {
                      final day = entry.key;
                      final hours = entry.value;
                      return ExpansionTile(
                        title: Text(day.toUpperCase()), // 曜日を表示
                        children: hours.isEmpty
                            ? [ListTile(title: Text('利用不可'))]
                            : hours.map((hour) => ListTile(title: Text(hour))).toList(),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      child: Text('この管理栄養士に決定'),
                      onPressed: () => _showConfirmationDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('確認'),
          content: Text('${nutritionist.name}さんを選択しますか？'),
          actions: <Widget>[
            TextButton(
              child: Text('キャンセル'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('決定'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Builderを使って新しいcontextを取得
                _confirmSelection(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmSelection(BuildContext context) async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);

    try {
      await userViewModel.selectNutritionist(nutritionist.nutritionist_id);

      // ホーム画面に戻る
      context.router.push(HomeRoute());
    } catch (e) {
      throw Exception('管理栄養士選択時にエラーが発生しました。');
    }
  }
}