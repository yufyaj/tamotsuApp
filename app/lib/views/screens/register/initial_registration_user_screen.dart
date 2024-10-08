import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tamotsu/routes/app_router.dart';
import 'package:tamotsu/viewmodels/auth_view_model.dart';
import 'package:tamotsu/viewmodels/user_view_model.dart';

@RoutePage()
class InitialRegistrationUserScreen extends StatefulWidget {
  final String email;
  final String verificationCode;
  final String userType;

  const InitialRegistrationUserScreen({
    Key? key,
    @PathParam('email') required this.email,
    @PathParam('verificationCode') required this.verificationCode,
    @PathParam('userType') required this.userType,
  }) : super(key: key);

  @override
  _InitialRegistrationScreenState createState() => _InitialRegistrationScreenState();
}

class _InitialRegistrationScreenState extends State<InitialRegistrationUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<void> _initFuture;
  late String email;
  late String verificationCode;
  late String? userType;
  String name = '';
  XFile? profileImage;
  int? age;
  String? gender;
  double? height;
  List<String> allergies = [];
  String? goals;
  List<String> dietaryRestrictions = [];
  String dislikedFoods = '';
  List<String> healthConcerns = [];

  String _password = '';
  String _confirmPassword = '';

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      email = widget.email;
      verificationCode = widget.verificationCode;
      userType = widget.userType;
    });
  }

// TODO: 登録時にエラーの場合、カーソル移動、登録ボタン押下時にロード画面
  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authViewModel.verifyEmail(verificationCode, email, _password);
      if (!success) {
        // TODO: パスワードのどこで引っ掛かったかをエラー表示する
        throw Exception('登録に失敗しました');
      }

      final loginSuccess = await authViewModel.login(email, _password);
      if (!loginSuccess) {
        throw Exception('ログインに失敗しました');
      }
        
      try {
        final Map<String, dynamic> data = {
        "name": name,
        "profileImage": profileImage != null ? File(profileImage!.path).readAsBytesSync() : null,
        "age": age,
        "gender": gender,
        "height": height,
        "allergies": allergies,
        "goals": goals,
        "dietaryRestrictions": dietaryRestrictions,
        "dislikedFoods": dislikedFoods,
        "healthConcerns": healthConcerns
      };

      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final profile_success = await userViewModel.updateUserProfile(data);

      if (!profile_success) {
        throw Exception('プロフィール更新に失敗しました');
      }

      context.router.push(NutritionistListRoute());

      } catch (e) {
        print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);

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
                        onChanged: (value) => setState(() => _password = value),
                        validator: (value) => value!.isEmpty ? 'パスワードを入力してください' : null,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'パスワード再入力'),
                        obscureText: true,
                        onChanged: (value) => setState(() => _confirmPassword = value),
                        validator: (value) {
                          if (value!.isEmpty) return 'パスワードを再入力してください';
                          if (value != _password) return 'パスワードが一致しません';
                          return null;
                        },
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'ニックネーム'),
                        validator: (value) => value!.isEmpty ? 'ニックネームを入力してください' : null,
                        onSaved: (value) => name = value!,
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
                      if (profileImage != null)
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: FileImage(File(profileImage!.path)),
                          ),
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
                      // アレルギー情報
                      Text('アレルギー情報'),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          '卵', '乳製品', '小麦', 'そば', '落花生', 'えび', 'かに'
                        ].map((allergy) {
                          return FilterChip(
                            label: Text(allergy),
                            selected: allergies.contains(allergy),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  allergies.add(allergy);
                                } else {
                                  allergies.removeWhere((String name) {
                                    return name == allergy;
                                  });
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'その他のアレルギー（自由記入）'),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            allergies.add(value);
                          }
                        },
                      ),
                      // 目標設定
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: '目標設定'),
                        items: [
                          '減量', '筋肉増強', '健康維持', '生活習慣改善', '栄養バランス改善',
                          '特定の栄養素摂取', '食事制限対応'
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => goals = value),
                        validator: (value) => value == null ? '目標を選択してください' : null,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'その他の目標（自由記入）'),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            goals = value;
                          }
                        },
                      ),
                      // 食事制限
                      Text('食事制限'),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          'ベジタリアン', 'ビーガン', 'グルテンフリー', '低糖質'
                        ].map((restriction) {
                          return FilterChip(
                            label: Text(restriction),
                            selected: dietaryRestrictions.contains(restriction),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  dietaryRestrictions.add(restriction);
                                } else {
                                  dietaryRestrictions.removeWhere((String name) {
                                    return name == restriction;
                                  });
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'その他の食事制限（自由記入）'),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            dietaryRestrictions.add(value);
                          }
                        },
                      ),
                      // 苦手な食材
                      TextFormField(
                        decoration: InputDecoration(labelText: '苦手な食材（自由記入）'),
                        onSaved: (value) => dislikedFoods = value!,
                      ),
                      // 健康上の懸念事項
                      Text('健康上の懸念事項'),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          '高血圧', '糖尿病', '高コレステロール'
                        ].map((concern) {
                          return FilterChip(
                            label: Text(concern),
                            selected: healthConcerns.contains(concern),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  healthConcerns.add(concern);
                                } else {
                                  healthConcerns.removeWhere((String name) {
                                    return name == concern;
                                  });
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'その他の健康上の懸念事項（自由記入）'),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            healthConcerns.add(value);
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: submitForm,
                        child: Text('次へ'),
                      ),
                      if (authViewModel.isLoading || userViewModel.isLoading)
                        CircularProgressIndicator(),
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
