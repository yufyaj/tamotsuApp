import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tamotsu/routes/app_router.dart';
import 'package:tamotsu/viewmodels/auth_view_model.dart';
import 'package:tamotsu/viewmodels/user_view_model.dart';

@RoutePage()
class UserProfileEditScreen extends StatefulWidget {

  const UserProfileEditScreen({
    Key? key,
  }) : super(key: key);

  @override
  _UserProfileEditScreenState createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<void> _initFuture;
  late String email;
  late String verificationCode;
  late String? userType;
  String name = '';
  XFile? profileImage;
  Uint8List? profileImageBytes;
  int? age;
  String? gender;
  double? height;
  List<String> allergies = [];
  List<String> goals = []; // 目標をリストとして管理
  List<String> dietaryRestrictions = [];
  String dislikedFoods = '';
  List<String> healthConcerns = [];

  // 初期値を保持するためのコントローラーを追加
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController dislikedFoodsController;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeData();

    // コントローラーを初期化
    nameController = TextEditingController();
    ageController = TextEditingController();
    heightController = TextEditingController();
    dislikedFoodsController = TextEditingController();
  }

  Future<void> _initializeData() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    await userViewModel.fetchUserProfile(); // ユーザープロフィールを取得

    // プロフィールデータを初期値に設定
    if (userViewModel.userProfile != null) {
      nameController.text = userViewModel.userProfile!['name'] ?? '';
      ageController.text = userViewModel.userProfile!['age'] ?? '';
      gender = userViewModel.userProfile!['gender'];
      heightController.text = userViewModel.userProfile!['height'] ?? '';
      allergies = List<String>.from(jsonDecode(userViewModel.userProfile!['allergies'] ?? '[]'));
      goals = List<String>.from(jsonDecode(userViewModel.userProfile!['goals'] ?? '[]'));
      dietaryRestrictions = List<String>.from(jsonDecode(userViewModel.userProfile!['dietary_restrictions'] ?? '[]'));
      dislikedFoodsController.text = userViewModel.userProfile!['disliked_foods'] ?? '';
      healthConcerns = List<String>.from(jsonDecode(userViewModel.userProfile!['health_concerns'] ?? '[]'));
      // プロフィール画像の設定は別途行う必要があります
      if (userViewModel.userProfile!['profile_image'] != null) {
          profileImageBytes = base64Decode(userViewModel.userProfile!['profile_image']);
      }
    }
  }

// TODO: 登録時にエラーの場合、カーソル移動、登録ボタン押下時にロード画面
  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
        
      try {
        final Map<String, dynamic> data = {
        "name": nameController.text,
        "profileImage": profileImage != null ? File(profileImage!.path).readAsBytesSync() : null,
        "age": ageController.text,
        "gender": gender,
        "height": heightController.text,
        "allergies": allergies,
        "goals": goals,
        "dietaryRestrictions": dietaryRestrictions,
        "dislikedFoods": dislikedFoodsController.text,
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
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'ニックネーム'),
                        validator: (value) => value!.isEmpty ? 'ニックネームを入力してください' : null,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setState(() {
                              profileImage      = image;
                              profileImageBytes = File(image.path).readAsBytesSync();
                            });
                          }
                        },
                        child: Text('プロフィール写真をアップロード'),
                      ),
                      if (profileImageBytes != null)
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: MemoryImage(profileImageBytes!),
                          ),
                        ),
                      TextFormField(
                        controller: ageController,
                        decoration: InputDecoration(labelText: '年齢'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? '年齢を入力してください' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: gender,
                        decoration: InputDecoration(labelText: '性別'),
                        items: ['男性', '女性', 'その他'].map((String value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => gender = value),
                        validator: (value) => value == null ? '性別を選択してください' : null,
                      ),
                      TextFormField(
                        controller: heightController,
                        decoration: InputDecoration(labelText: '身長 (cm)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? '身長を入力してください' : null,
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
                        initialValue: allergies.where((allergy) => !['卵', '乳製品', '小麦', 'そば', '落花生', 'えび', 'かに'].contains(allergy)).join(', '),
                        onSaved: (value) {
                          allergies.removeWhere((allergy) => !['卵', '乳製品', '小麦', 'そば', '落花生', 'えび', 'かに'].contains(allergy));
                          if (value != null && value.isNotEmpty) {
                            final newItems = value.split(',').map((e) => e.trim()).toSet();
                            allergies.addAll(newItems.difference(allergies.toSet()));
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
                        onChanged: (value) => setState((){
                          if (value != null && value.isNotEmpty) {
                            goals.clear();
                            goals.add(value);
                          }
                        }),
                        validator: (value) => goals.length == 0 ? '目標を選択してください' : null,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'その他の目標（自由記入）'),
                        initialValue: goals.where((goal) => !['減量', '筋肉増強', '健康維持', '生活習慣改善', '栄養バランス改善', '特定の栄養素摂取', '食事制限対応'].contains(goal)).join(', '),
                        onChanged: (value) {
                          setState((){
                            if (value != null && value.isNotEmpty && !goals.contains('その他')) {
                              goals.add('その他');
                            }
                          });
                        },
                        onSaved: (value) {
                          goals.removeWhere((goals) => !['減量', '筋肉増強', '健康維持', '生活習慣改善', '栄養バランス改善', '特定の栄養素摂取', '食事制限対応'].contains(goals));
                          if (value != null && value.isNotEmpty) {
                            final newItems = value.split(',').map((e) => e.trim()).toSet();
                            goals.addAll(newItems.difference(goals.toSet()));
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
                        initialValue: dietaryRestrictions.where((restriction) => !['ベジタリアン', 'ビーガン', 'グルテンフリー', '低糖質'].contains(restriction)).join(', '),
                        onSaved: (value) {
                          dietaryRestrictions.removeWhere((dietaryRestriction) => !['ベジタリアン', 'ビーガン', 'グルテンフリー', '低糖質'].contains(dietaryRestriction));
                          if (value != null && value.isNotEmpty) {
                            final newItems = value.split(',').map((e) => e.trim()).toSet();
                            dietaryRestrictions.addAll(newItems.difference(dietaryRestrictions.toSet()));
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
                        initialValue: healthConcerns.where((concern) => !['高血圧', '糖尿病', '高コレステロール'].contains(concern)).join(', '),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            healthConcerns.removeWhere((healthConcern) => !['高血圧', '糖尿病', '高コレステロール'].contains(healthConcern));
                            final newItems = value.split(',').map((e) => e.trim()).toSet();
                            healthConcerns.addAll(newItems.difference(healthConcerns.toSet()));
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