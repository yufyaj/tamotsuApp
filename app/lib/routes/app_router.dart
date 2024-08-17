import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:tamotsu/models/nutritionist.dart';
import 'package:tamotsu/views/screens/login_screen.dart';
import 'package:tamotsu/views/screens/register/initial_registration_user_screen.dart';
import 'package:tamotsu/views/screens/register/initial_registration_nutritionist_screen.dart';
import 'package:tamotsu/views/screens/register/register_screen.dart';
import 'package:tamotsu/views/screens/home_screen.dart';
import 'package:tamotsu/views/screens/test_screen.dart';
import 'package:tamotsu/views/screens/register/nutritionist_list_screen.dart';
import 'package:tamotsu/views/screens/register/nutritionist_detail_screen.dart';
// 他の画面もここにインポートしてください

part 'app_router.gr.dart';

@AutoRouterConfig(
  replaceInRouteName: 'Screen,Route',
)
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, initial: true),
    AutoRoute(page: InitialRegistrationUserRoute.page),
    AutoRoute(page: InitialRegistrationNutritionistRoute.page),
    AutoRoute(page: RegisterRoute.page),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: TestRoute.page),
    AutoRoute(page: NutritionistDetailRoute.page),
    AutoRoute(page: NutritionistListRoute.page)
  ];
}