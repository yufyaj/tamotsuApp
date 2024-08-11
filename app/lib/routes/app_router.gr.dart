// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomeScreen(),
      );
    },
    InitialRegistrationNutritionistRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<InitialRegistrationNutritionistRouteArgs>(
          orElse: () => InitialRegistrationNutritionistRouteArgs(
                email: pathParams.getString('email'),
                verificationCode: pathParams.getString('verificationCode'),
                userType: pathParams.getString('userType'),
              ));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: InitialRegistrationNutritionistScreen(
          key: args.key,
          email: args.email,
          verificationCode: args.verificationCode,
          userType: args.userType,
        ),
      );
    },
    InitialRegistrationUserRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<InitialRegistrationUserRouteArgs>(
          orElse: () => InitialRegistrationUserRouteArgs(
                email: pathParams.getString('email'),
                verificationCode: pathParams.getString('verificationCode'),
                userType: pathParams.getString('userType'),
              ));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: InitialRegistrationUserScreen(
          key: args.key,
          email: args.email,
          verificationCode: args.verificationCode,
          userType: args.userType,
        ),
      );
    },
    LoginRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: LoginScreen(),
      );
    },
    RegisterRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: RegisterScreen(),
      );
    },
    TestRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const TestScreen(),
      );
    },
  };
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [InitialRegistrationNutritionistScreen]
class InitialRegistrationNutritionistRoute
    extends PageRouteInfo<InitialRegistrationNutritionistRouteArgs> {
  InitialRegistrationNutritionistRoute({
    Key? key,
    required String email,
    required String verificationCode,
    required String userType,
    List<PageRouteInfo>? children,
  }) : super(
          InitialRegistrationNutritionistRoute.name,
          args: InitialRegistrationNutritionistRouteArgs(
            key: key,
            email: email,
            verificationCode: verificationCode,
            userType: userType,
          ),
          rawPathParams: {
            'email': email,
            'verificationCode': verificationCode,
            'userType': userType,
          },
          initialChildren: children,
        );

  static const String name = 'InitialRegistrationNutritionistRoute';

  static const PageInfo<InitialRegistrationNutritionistRouteArgs> page =
      PageInfo<InitialRegistrationNutritionistRouteArgs>(name);
}

class InitialRegistrationNutritionistRouteArgs {
  const InitialRegistrationNutritionistRouteArgs({
    this.key,
    required this.email,
    required this.verificationCode,
    required this.userType,
  });

  final Key? key;

  final String email;

  final String verificationCode;

  final String userType;

  @override
  String toString() {
    return 'InitialRegistrationNutritionistRouteArgs{key: $key, email: $email, verificationCode: $verificationCode, userType: $userType}';
  }
}

/// generated route for
/// [InitialRegistrationUserScreen]
class InitialRegistrationUserRoute
    extends PageRouteInfo<InitialRegistrationUserRouteArgs> {
  InitialRegistrationUserRoute({
    Key? key,
    required String email,
    required String verificationCode,
    required String userType,
    List<PageRouteInfo>? children,
  }) : super(
          InitialRegistrationUserRoute.name,
          args: InitialRegistrationUserRouteArgs(
            key: key,
            email: email,
            verificationCode: verificationCode,
            userType: userType,
          ),
          rawPathParams: {
            'email': email,
            'verificationCode': verificationCode,
            'userType': userType,
          },
          initialChildren: children,
        );

  static const String name = 'InitialRegistrationUserRoute';

  static const PageInfo<InitialRegistrationUserRouteArgs> page =
      PageInfo<InitialRegistrationUserRouteArgs>(name);
}

class InitialRegistrationUserRouteArgs {
  const InitialRegistrationUserRouteArgs({
    this.key,
    required this.email,
    required this.verificationCode,
    required this.userType,
  });

  final Key? key;

  final String email;

  final String verificationCode;

  final String userType;

  @override
  String toString() {
    return 'InitialRegistrationUserRouteArgs{key: $key, email: $email, verificationCode: $verificationCode, userType: $userType}';
  }
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [RegisterScreen]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [TestScreen]
class TestRoute extends PageRouteInfo<void> {
  const TestRoute({List<PageRouteInfo>? children})
      : super(
          TestRoute.name,
          initialChildren: children,
        );

  static const String name = 'TestRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
