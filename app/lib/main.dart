import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tamotsu/services/auth_service.dart';
import 'package:tamotsu/viewmodels/auth_view_model.dart';
import 'package:tamotsu/routes/app_router.dart';
import 'package:uni_links/uni_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  final appRouter = AppRouter();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authService: AuthService())),
        // 他のViewModelもここに追加
      ],
      child: TamotsuApp(appRouter: appRouter),
    ),
  );
}

class TamotsuApp extends StatefulWidget {
  final AppRouter appRouter;
  
  const TamotsuApp({Key? key, required this.appRouter}) : super(key: key);

  @override
  _TamotsuAppState createState() => _TamotsuAppState();
}

class _TamotsuAppState extends State<TamotsuApp> {
  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  Future<void> initUniLinks() async {
    // Deep Linkの初期化
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(Uri.parse(initialLink));
        });
      }
    } catch (e) {
      print('Error getting initial link: $e');
    }

    // リスナーを設定して、アプリが起動中にDeep Linkを受け取った場合の処理
    uriLinkStream.listen((Uri? link) {
      if (link != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(link);
        });
      }
    }, onError: (err) {
      print('Error in uri link stream: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    switch (uri.host) {
      case 'verify':
        final email = uri.queryParameters['email'];
        final verificationCode = uri.queryParameters['verificationCode'];
        final userType = uri.queryParameters['userType'];

        if (email != null && verificationCode != null && userType != null) {
          setState(() {
            widget.appRouter.push(InitialRegistrationRoute(
              email: email,
              verificationCode: verificationCode,
              userType: userType,
            ));
          });
        }
        break;
      case 'test':
        widget.appRouter.push(const TestRoute());
      default:
        widget.appRouter.push(const LoginRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'TAMOTSU',
          theme: ThemeData(
            primarySwatch: Colors.lightGreen,
            // textTheme: Typography.englishLike2018.apply(
            //   fontSizeFactor: 1.sp,
            //   bodyColor: Colors.black,
            //   displayColor: Colors.black,
            // ),
          ),
          routerDelegate: widget.appRouter.delegate(),
          routeInformationParser: widget.appRouter.defaultRouteParser(),
        );
      },
    );
  }
}
