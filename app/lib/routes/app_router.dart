import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:tamotsu/views/screens/login_screen.dart';
import 'package:tamotsu/views/screens/initial_registration_screen.dart';
import 'package:tamotsu/views/screens/register_screen.dart';
import 'package:tamotsu/views/screens/home_screen.dart';
import 'package:tamotsu/views/screens/test_screen.dart';
// 他の画面もここにインポートしてください

part 'app_router.gr.dart';

@AutoRouterConfig(
  replaceInRouteName: 'Screen,Route',
)
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginRoute.page, initial: true),
    AutoRoute(page: InitialRegistrationRoute.page),
    AutoRoute(page: RegisterRoute.page),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: TestRoute.page),
  ];
}