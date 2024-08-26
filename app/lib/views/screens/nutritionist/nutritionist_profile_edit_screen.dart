import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tamotsu/routes/app_router.dart';
import 'package:tamotsu/viewmodels/auth_view_model.dart';
import 'package:tamotsu/viewmodels/nutritionist_view_model.dart';

@RoutePage()
class NutritionistProfileEditScreen extends StatefulWidget {

  const NutritionistProfileEditScreen({
    Key? key,
  }) : super(key: key);

  @override
  _NutritionistProfileEditScreenState createState() => _NutritionistProfileEditScreenState();
}

class _NutritionistProfileEditScreenState extends State<NutritionistProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future _initFuture;
  String name = '';
  XFile? profileImage;
  Uint8List? profileImageBytes;
  String qualifications = '';
  String introduce = '';
  Map<String, List<String>> availableHours = {
    'monday': [], 'tuesday': [], 'wednesday': [], 'thursday': [], 'friday': [], 'saturday': [], 'sunday': []
  };
  List<String> specialties = [];

  // 初期値を保持するためのコントローラーを追加
  late TextEditingController nameController;
  late TextEditingController qualificationsController;
  late TextEditingController introduceController;
  late TextEditingController dislikedFoodsController;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeData();

    // コントローラーを初期化
    nameController = TextEditingController();
    qualificationsController = TextEditingController();
    introduceController = TextEditingController();
    dislikedFoodsController = TextEditingController();
  }

  Future _initializeData() async {
    final nutritionistViewModel = Provider.of<NutritionistViewModel>(context, listen: false);
    await nutritionistViewModel.fetchNutritionistProfile(); // ユーザープロフィールを取得

    // プロフィールデータを初期値に設定
    if (nutritionistViewModel.nutritionistProfile != null) {
      nameController.text = nutritionistViewModel.nutritionistProfile!['name'] ?? '';
      qualificationsController.text = nutritionistViewModel.nutritionistProfile!['qualifications'] ?? '';
      introduceController.text = nutritionistViewModel.nutritionistProfile!['introduce'];
      specialties = List<String>.from(jsonDecode(nutritionistViewModel.nutritionistProfile!['specialties'] ?? '[]'));
      if (nutritionistViewModel.nutritionistProfile!['available_hours'] != null) {
        availableHours = Map<String, List<String>>.from(nutritionistViewModel.nutritionistProfile!['available_hours'].map((key, value) => MapEntry(key, List<String>.from(value))));
      }
      // プロフィール画像の設定は別途行う必要があります
      if (nutritionistViewModel.nutritionistProfile!['profile_image'] != null) {
          profileImageBytes = base64Decode(nutritionistViewModel.nutritionistProfile!['profile_image']);
      }
    }
  }

// TODO: 登録時にエラーの場合、カーソル移動、登録ボタン押下時にロード画面
// TODO: エラー時に通知バーを表示
  Future submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final Map<String, dynamic> data = {
        "name": name,
        "profileImage": profileImage != null ? await File(profileImage!.path).readAsBytes() : null,
        "qualifications": qualifications,
        "introduce": introduce,
        "specialties": specialties,
        "availableHours": availableHours,
      };

      final nutritionistViewModel = Provider.of<NutritionistViewModel>(context, listen: false);
      final profileSuccess = await nutritionistViewModel.updateNutritionistProfile(data);
      if (!profileSuccess) {
        throw Exception('プロフィール更新に失敗しました');
      }

      context.router.push(const HomeRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel         = Provider.of<AuthViewModel>(context, listen: false);
    final nutritionistViewModel = Provider.of<NutritionistViewModel>(context, listen: false);


    return Scaffold(
      appBar: AppBar(
        title: Text('栄養士初期登録'),
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
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: '名前'),
                        validator: (value) => value!.isEmpty ? '名前を入力してください' : null,
                        onSaved: (value) => name = value!,
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
                        controller: qualificationsController,
                        decoration: InputDecoration(labelText: '資格'),
                        validator: (value) => value!.isEmpty ? '資格を入力してください' : null,
                        onSaved: (value) => qualifications = value!,
                      ),
                      TextFormField(
                        controller: introduceController,
                        decoration: InputDecoration(labelText: '自己紹介'),
                        maxLines: 3,
                        validator: (value) => value!.isEmpty ? '自己紹介を入力してください' : null,
                        onSaved: (value) => introduce = value!,
                      ),
                      Text('得意分野'),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          'ダイエット', 'スポーツ栄養', '食物アレルギー', '糖尿病食', '高血圧食', '腎臓病食', '妊婦・授乳婦栄養'
                        ].map((specialty) {
                          return FilterChip(
                            label: Text(specialty),
                            selected: specialties.contains(specialty),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  specialties.add(specialty);
                                } else {
                                  specialties.removeWhere((String name) {
                                    return name == specialty;
                                  });
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'その他の得意分野（自由記入）'),
                        initialValue: specialties.where((specialty) => !['ダイエット', 'スポーツ栄養', '食物アレルギー', '糖尿病食', '高血圧食', '腎臓病食', '妊婦・授乳婦栄養'].contains(specialty)).join(', '),
                        onSaved: (value) {
                          specialties.removeWhere((specialty) => !['ダイエット', 'スポーツ栄養', '食物アレルギー', '糖尿病食', '高血圧食', '腎臓病食', '妊婦・授乳婦栄養'].contains(specialty));
                          if (value != null && value.isNotEmpty) {
                            final newItems = value.split(',').map((e) => e.trim()).toSet();
                            specialties.addAll(newItems.difference(specialties.toSet()));
                          }
                        },
                      ),
                      Text('対応可能日時'),
                      ...['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'].map((day) {
                        return ExpansionTile(
                          title: Text(day.toUpperCase()),
                          children: [
                            CheckboxListTile(
                              title: Text('午前（9:00-12:00）'),
                              value: availableHours[day]!.contains('9:00-12:00'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value!) {
                                    availableHours[day]!.add('9:00-12:00');
                                  } else {
                                    availableHours[day]!.remove('9:00-12:00');
                                  }
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: Text('午後（13:00-17:00）'),
                              value: availableHours[day]!.contains('13:00-17:00'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value!) {
                                    availableHours[day]!.add('13:00-17:00');
                                  } else {
                                    availableHours[day]!.remove('13:00-17:00');
                                  }
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: Text('夜間（18:00-21:00）'),
                              value: availableHours[day]!.contains('18:00-21:00'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value!) {
                                    availableHours[day]!.add('18:00-21:00');
                                  } else {
                                    availableHours[day]!.remove('18:00-21:00');
                                  }
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: submitForm,
                        child: Text('登録'),
                      ),
                      if (authViewModel.isLoading || nutritionistViewModel.isLoading)
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
