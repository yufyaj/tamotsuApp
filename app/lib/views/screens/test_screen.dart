import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

import '../../routes/app_router.dart';

@RoutePage()
class TestScreen extends StatelessWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('テスト画面'),
      ),
      backgroundColor: Colors.blue,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              'ようこそ！',
              style: TextStyle(fontSize: 24),
            ),
            TextButton(
              child: Text('これはテストです。これはテストです。これはテストです。'),
              onPressed: () {
                context.router.push(InitialRegistrationUserRoute(email: '', verificationCode: '', userType: ''));
              },
            ),
          ]
        )
      ),
    );
  }
}
