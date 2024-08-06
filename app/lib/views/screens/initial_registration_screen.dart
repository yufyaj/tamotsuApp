import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

@RoutePage()
class InitialRegistrationScreen extends StatefulWidget {
  final String email;
  final String verificationCode;
  final String userType;

  const InitialRegistrationScreen({
    Key? key,
    @PathParam('email') required this.email,
    @PathParam('verificationCode') required this.verificationCode,
    @PathParam('userType') required this.userType,
  }) : super(key: key);

  @override
  _InitialRegistrationScreenState createState() => _InitialRegistrationScreenState();
}

class _InitialRegistrationScreenState extends State<InitialRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<void> _initFuture;
  late String email;
  late String verificationCode;
  late String? userType;
  String password = '';
  String confirmPassword = '';
  String nickname = '';
  XFile? profileImage;
  int? age;
  String? gender;
  double? height;
  double? weight;
  List<String> allergies = [];
  String? goal;
  List<String> dietaryRestrictions = [];
  String dislikedFoods = '';
  List<String> healthConcerns = [];

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    // シミュレートされた遅延
    // await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      email = widget.email;
      verificationCode = widget.verificationCode;
      userType = widget.userType;
    });
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final Map<String, dynamic> data = {
        'email': email,
        'verificationCode': verificationCode,
        'userType': userType,
        'password': password,
        'name': nickname,
        'birthDate': DateTime.now().subtract(Duration(days: age! * 365)).toIso8601String().split('T')[0],
        'gender': gender,
        'height': height,
        'weight': weight,
        'allergies': allergies,
        'goal': goal,
        'dietaryRestrictions': dietaryRestrictions.join(', '),
        'dislikedFoods': dislikedFoods,
        'healthConcerns': healthConcerns,
      };

      try {
        final response = await http.post(
          Uri.parse('https://api.tamotsu-app.com/verify-email'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('登録が完了しました')));
          // 登録成功後、ホーム画面に遷移
          context.router.pushNamed('/home');
        } else {
          throw Exception('登録に失敗しました');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('登録に失敗しました: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('初期登録'),
        leading: AutoLeadingButton(),
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          } else {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'パスワード'),
                        obscureText: true,
                        validator: (value) => value!.isEmpty ? 'パスワードを入力してください' : null,
                        onSaved: (value) => password = value!,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'パスワード再入力'),
                        obscureText: true,
                        validator: (value) => value != password ? 'パスワードが一致しません' : null,
                        onSaved: (value) => confirmPassword = value!,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'ニックネーム'),
                        validator: (value) => value!.isEmpty ? 'ニックネームを入力してください' : null,
                        onSaved: (value) => nickname = value!,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setState(() {
                              profileImage = image;
                            });
                          }
                        },
                        child: Text('プロフィール写真をアップロード'),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: '年齢'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? '年齢を入力してください' : null,
                        onSaved: (value) => age = int.parse(value!),
                      ),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: '性別'),
                        items: ['男性', '女性', 'その他'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => gender = value),
                        validator: (value) => value == null ? '性別を選択してください' : null,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: '身長 (cm)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? '身長を入力してください' : null,
                        onSaved: (value) => height = double.parse(value!),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: '体重 (kg)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? '体重を入力してください' : null,
                        onSaved: (value) => weight = double.parse(value!),
                      ),
                      // アレルギー情報、目標設定、食事制限、苦手な食材、健康上の懸念事項の入力フィールドは
                      // 同様の方法で実装できます。紙面の都合上、省略しています。

                      ElevatedButton(
                        onPressed: submitForm,
                        child: Text('次へ'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}