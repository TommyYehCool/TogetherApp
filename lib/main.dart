import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'services/activity_service.dart';
import 'config/env_config.dart';

Future<void> main() async {
  // 確保 Flutter 綁定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 載入環境變數
  try {
    await dotenv.load(fileName: '.env');
    print('✅ 環境變數載入成功');
    
    // Debug 模式下顯示配置
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      EnvConfig.printConfig();
    }
  } catch (e) {
    print('⚠️ 環境變數載入失敗: $e');
    print('將使用預設配置');
  }
  
  runApp(const TogetherApp());
}

class TogetherApp extends StatelessWidget {
  const TogetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityService()),
      ],
      child: MaterialApp(
        title: 'Together',
        debugShowCheckedModeBanner: false,
        // 繁體中文支援
        locale: const Locale('zh', 'TW'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'TW'), // 繁體中文
          Locale('en', 'US'), // 英文
        ],
        theme: ThemeData(
          primaryColor: const Color(0xFF00D0DD),
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00D0DD),
            primary: const Color(0xFF00D0DD),
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
