import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tamotsu/viewmodels/auth_view_model.dart';

@RoutePage()
class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  bool _isNutritionist = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      try {
        final success = await authViewModel.register(_email, _isNutritionist ? 'nutritionist' : 'user');
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('仮登録が完了しました。メールをご確認ください。')),
          );
          // 登録成功後、ログイン画面に戻る
          // ignore: deprecated_member_use
          context.router.pop();
        } else {
          throw Exception('登録に失敗しました');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録に失敗しました。もう一度お試しください。')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('新規登録'),
        leading: AutoLeadingButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
                    if (!value.contains('@')) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value!,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('利用者'),
                    Switch(
                      value: _isNutritionist,
                      onChanged: (value) {
                        setState(() {
                          _isNutritionist = value;
                        });
                      },
                    ),
                    Text('管理栄養士'),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('仮登録'),
                  onPressed: authViewModel.isLoading ? null : _register,
                ),
                SizedBox(height: 10),
                TextButton(
                  child: Text('戻る'),
                  onPressed: () => context.router.pop(),
                ),
                if (authViewModel.isLoading)
                  CircularProgressIndicator(),
                if (authViewModel.error != null)
                  Text(authViewModel.error!, style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
