import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, kDebugMode;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'presentation/state/providers/face_login_provider.dart';
import 'presentation/state/providers/verify_token_provider.dart';
import 'package:itms_mobile/core/config/env.dart';
import 'package:itms_mobile/core/config/app_theme.dart';
import 'package:itms_mobile/core/utils/web_error_handler.dart';
import 'package:itms_mobile/core/utils/web_type_safety.dart';
import 'package:itms_mobile/services/notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化环境配置 - 使用Web错误处理器
    await WebErrorHandler.safeVoid(() async {
      await Env.init();
    });
    
    // 确保环境配置已正确初始化
    if (kIsWeb) {
      final config = WebTypeSafety.safeGetConfig(() => Env.config);
      if (config != null && kDebugMode) {
        print('环境配置已加载: ${config.appName}');
      }
    }
    
    // 初始化通知服务
    if (!kIsWeb) {
      await NotificationService.initialize();
      await NotificationService.requestPermission();
    }
    
    // 配置EasyLoading
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.dark
      ..maskType = EasyLoadingMaskType.black
      ..dismissOnTap = false;
      
    // 在启动屏结束后执行系统UI设置
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // 设置系统UI样式
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            // 状态栏（顶部）
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            // 导航栏（底部虚拟按键区域）
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
            // 导航栏分隔线颜色（设置为透明以确保完全透明）
            systemNavigationBarDividerColor: Colors.transparent,
          ));
          // 设置底部虚拟按键始终隐藏
          _hideBottomNavigationBar();
        } catch (e) {
          // 系统UI设置失败时继续运行
          if (kDebugMode) {
            print('系统UI设置失败: $e');
          }
        }
      });
    }
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // 如果main函数出现严重错误，显示错误信息
    if (kDebugMode) {
      print('应用启动失败: $e');
      print('堆栈跟踪: $stackTrace');
    }
    // 即使出现错误也要尝试运行应用
    runApp(const MyApp());
  }
}

/// 隐藏底部导航栏（虚拟按键）
/// 注意：此功能主要在原生 Android 代码中实现
void _hideBottomNavigationBar() {
  try {
    // 设置系统UI样式
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    
    // 使用 edgeToEdge 模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } catch (e) {
    if (kDebugMode) {
      print('设置系统UI失败: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 当应用状态改变时，重新设置底部导航栏隐藏
    if (state == AppLifecycleState.resumed) {
      _hideBottomNavigationBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FaceLoginProvider>(
          create: (_) => WebTypeSafety.safeCreateProvider(() => FaceLoginProvider()),
        ),
        ChangeNotifierProvider<VerifyTokenProvider>(
          create: (_) => WebTypeSafety.safeCreateProvider(() => VerifyTokenProvider(access_token: '')),
        ),
      ],
      child: MaterialApp(
        title: _getAppTitle(),
        theme: AppTheme.theme,
        initialRoute: '/',
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: RouteGenerator.generateRoute,
        builder: EasyLoading.init(
          builder: (context, child) {
            try {
              if (kIsWeb) {
                final MediaQueryData? mediaQuery = WebTypeSafety.safeGetMediaQuery(context);
                final ThemeData? theme = WebTypeSafety.safeGetTheme(context);
                
                if (mediaQuery != null && theme != null) {
                  return MediaQuery(
                    data: mediaQuery.copyWith(textScaleFactor: 1.0),
                    child: Theme(
                      data: theme.copyWith(
                        // Web端额外禁用点击反馈
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                      ),
                      child: child!,
                    ),
                  );
                }
              }
              return child!;
            } catch (e) {
              // 如果构建失败，返回错误页面
              return MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('应用初始化失败: $e'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // 尝试重新启动应用
                            runApp(const MyApp());
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
  
  String _getAppTitle() {
    final config = WebTypeSafety.safeGetConfig(() => Env.config);
    return config?.appName ?? '智慧仓储系统';
  }
}
