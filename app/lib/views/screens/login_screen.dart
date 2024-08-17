import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tamotsu/routes/app_router.dart';
import 'package:tamotsu/viewmodels/auth_view_model.dart';

@RoutePage()
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      try {
        final success = await authViewModel.login(_email, _password);
        if (success) {
          final userType = await authViewModel.getAuthUserType();
          if (userType == 'user') {
            context.router.push(const HomeRoute());
          } else if(userType == 'nutritionist') {
            context.router.push(const HomeRoute());
          } else {
            throw Exception('ログインに失敗しました');
          }
        } else {
          throw Exception('ログインに失敗しました');
        }
      } catch (e) {
        String errorMessage = 'ログインに失敗しました。もう一度お試しください。';
        if (e is Exception) {
          errorMessage = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: 20),
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                  SizedBox(height: 48.0),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'メールアドレス',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'メールアドレスを入力してください';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() => _email = value),
                    onFieldSubmitted: (_) => _login(),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'パスワードを入力してください';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() => _password = value),
                    onFieldSubmitted: (_) => _login(),
                  ),
                  SizedBox(height: 24.0),
                  ElevatedButton(
                    child: Text('ログイン'),
                    onPressed: _login,
                  ),
                  SizedBox(height: 16.0),
                  TextButton(
                    child: Text('パスワードをお忘れですか？'),
                    onPressed: () {
                      // パスワードリセット画面への遷移
                      context.router.push(NutritionistListRoute());
                    },
                  ),
                  TextButton(
                    child: Text('アカウントをお持ちでない方はこちら'),
                    onPressed: () {
                      // 登録画面への遷移
                      context.router.push(RegisterRoute());
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}