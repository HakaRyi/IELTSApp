import 'package:flutter/material.dart';
import 'core/auth_controller.dart';
import 'core/server_config_store.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/floating_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServerConfigStore.load(); // nạp URL server đã lưu (nếu có)
  runApp(const IeltsVocabApp());
}

class IeltsVocabApp extends StatefulWidget {
  const IeltsVocabApp({super.key});

  @override
  State<IeltsVocabApp> createState() => _IeltsVocabAppState();
}

class _IeltsVocabAppState extends State<IeltsVocabApp> {
  final _auth = AuthController();

  @override
  void initState() {
    super.initState();
    _auth.tryAutoLogin();
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IELTS Vocab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AnimatedBuilder(
        animation: _auth,
        builder: (context, _) {
          switch (_auth.status) {
            case AuthStatus.unknown:
              return const _SplashScreen();
            case AuthStatus.authenticated:
              return HomeScreen(auth: _auth);
            case AuthStatus.unauthenticated:
              return LoginScreen(auth: _auth);
          }
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingBackground()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 42),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
