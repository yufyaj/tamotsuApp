import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tamotsu/routes/app_router.dart';
import 'package:tamotsu/viewmodels/auth_view_model.dart';
import 'package:tamotsu/viewmodels/nutritionist_view_model.dart';

@RoutePage()
class InitialRegistrationNutritionistScreen extends StatefulWidget {
  final String email;
  final String verificationCode;
  final String userType;

  const InitialRegistrationNutritionistScreen({
    Key? key,
    @PathParam('email') required this.email,
    @PathParam('verificationCode') required this.verificationCode,
    @PathParam('userType') required this.userType,
  }) : super(key: key);

  @override
  _InitialRegistrationNutritionistScreenState createState() => _InitialRegistrationNutritionistScreenState();
}

class _InitialRegistrationNutritionistScreenState extends State<InitialRegistrationNutritionistScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future _initFuture;
  late String email;
  late String verificationCode;
  late String? userType;
  String name = '';
  XFile? profileImage;
  String qualifications = '';
  String introduce = '';
  Map<String, List<String>> availableHours = {
    'monday': [], 'tuesday': [], 'wednesday': [], 'thursday': [], 'friday': [], 'saturday': [], 'sunday': []
  };
  List<String> specialties = [];

  String _password = '';
  String _confirmPassword = '';


  @override
  void initState() {
    super.initState();
    _initFuture = _initializeData();
  }

  Future _initializeData() async {
    setState(() {
      email = widget.email;
      verificationCode = widget.verificationCode;
      userType = widget.userType;
    });
  }

  Future submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      // final success = await authViewModel.verifyEmail(verificationCode, email, _password);
      // if (!success) {
      //   throw Exception('登録に失敗しました');
      // }

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
                        decoration: InputDecoration(labelText: '資格'),
                        validator: (value) => value!.isEmpty ? '資格を入力してください' : null,
                        onSaved: (value) => qualifications = value!,
                      ),
                      TextFormField(
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
                                  specialties.remove(specialty);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'その他の得意分野（自由記入）'),
                        onSaved: (value) {
                          if (value != null && value.isNotEmpty) {
                            specialties.add(value);
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
