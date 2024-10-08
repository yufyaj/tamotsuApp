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
    ChatRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ChatScreen(),
      );
    },
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
    NutritionistDetailRoute.name: (routeData) {
      final args = routeData.argsAs<NutritionistDetailRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: NutritionistDetailScreen(
          key: args.key,
          nutritionist: args.nutritionist,
        ),
      );
    },
    NutritionistHomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: NutritionistHomeScreen(),
      );
    },
    NutritionistListRoute.name: (routeData) {
      final args = routeData.argsAs<NutritionistListRouteArgs>(
          orElse: () => const NutritionistListRouteArgs());
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: NutritionistListScreen(key: args.key),
      );
    },
    NutritionistProfileEditRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const NutritionistProfileEditScreen(),
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
    UserHomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: UserHomeScreen(),
      );
    },
    UserProfileEditRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const UserProfileEditScreen(),
      );
    },
  };
}

/// generated route for
/// [ChatScreen]
class ChatRoute extends PageRouteInfo<void> {
  const ChatRoute({List<PageRouteInfo>? children})
      : super(
          ChatRoute.name,
          initialChildren: children,
        );

  static const String name = 'ChatRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
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
/// [NutritionistDetailScreen]
class NutritionistDetailRoute
    extends PageRouteInfo<NutritionistDetailRouteArgs> {
  NutritionistDetailRoute({
    Key? key,
    required Nutritionist nutritionist,
    List<PageRouteInfo>? children,
  }) : super(
          NutritionistDetailRoute.name,
          args: NutritionistDetailRouteArgs(
            key: key,
            nutritionist: nutritionist,
          ),
          initialChildren: children,
        );

  static const String name = 'NutritionistDetailRoute';

  static const PageInfo<NutritionistDetailRouteArgs> page =
      PageInfo<NutritionistDetailRouteArgs>(name);
}

class NutritionistDetailRouteArgs {
  const NutritionistDetailRouteArgs({
    this.key,
    required this.nutritionist,
  });

  final Key? key;

  final Nutritionist nutritionist;

  @override
  String toString() {
    return 'NutritionistDetailRouteArgs{key: $key, nutritionist: $nutritionist}';
  }
}

/// generated route for
/// [NutritionistHomeScreen]
class NutritionistHomeRoute extends PageRouteInfo<void> {
  const NutritionistHomeRoute({List<PageRouteInfo>? children})
      : super(
          NutritionistHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'NutritionistHomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [NutritionistListScreen]
class NutritionistListRoute extends PageRouteInfo<NutritionistListRouteArgs> {
  NutritionistListRoute({
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          NutritionistListRoute.name,
          args: NutritionistListRouteArgs(key: key),
          initialChildren: children,
        );

  static const String name = 'NutritionistListRoute';

  static const PageInfo<NutritionistListRouteArgs> page =
      PageInfo<NutritionistListRouteArgs>(name);
}

class NutritionistListRouteArgs {
  const NutritionistListRouteArgs({this.key});

  final Key? key;

  @override
  String toString() {
    return 'NutritionistListRouteArgs{key: $key}';
  }
}

/// generated route for
/// [NutritionistProfileEditScreen]
class NutritionistProfileEditRoute extends PageRouteInfo<void> {
  const NutritionistProfileEditRoute({List<PageRouteInfo>? children})
      : super(
          NutritionistProfileEditRoute.name,
          initialChildren: children,
        );

  static const String name = 'NutritionistProfileEditRoute';

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

/// generated route for
/// [UserHomeScreen]
class UserHomeRoute extends PageRouteInfo<void> {
  const UserHomeRoute({List<PageRouteInfo>? children})
      : super(
          UserHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserHomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [UserProfileEditScreen]
class UserProfileEditRoute extends PageRouteInfo<void> {
  const UserProfileEditRoute({List<PageRouteInfo>? children})
      : super(
          UserProfileEditRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserProfileEditRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
