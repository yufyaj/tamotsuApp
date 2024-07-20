import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/logo.png', // ロゴ画像 (例: 葉っぱやハートのマーク)
                  height: 100.0,
                ),
                const SizedBox(height: 48.0),
                TextFormField(
                  key: const Key('emailField'),
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!value.contains('@')) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                TextFormField(
                  key: const Key('passwordField'),
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A), // 緑系の色
                    padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 12.0),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: ログイン処理を実装
                    }
                  },
                  child: const Text(
                    'ログイン',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                const SizedBox(height: 18.0),
                TextButton(
                  onPressed: () {
                    // TODO: 新規登録画面へ遷移
                  },
                  child: const Text(
                    '新規登録はこちら',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
