import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:logger/logger.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/loading_widget.dart';
import '../widgets/update_required_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final authC = Get.find<AuthController>();
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _logger.i('SplashPage: Starting app initialization');

      // Start navigation timer
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigate();
        }
      });
    } catch (e) {
      // Log error but don't block app startup
      debugPrint('App initialization failed: $e');
      _navigate(); // Still navigate even if initialization fails
    }
  }

  Future<void> _navigate() async {
    // Add a small delay to ensure smooth transition
    await Future.delayed(const Duration(seconds: 1));

    await authC.checkLoginStatus();

    if (mounted) {
      if (authC.isLoggedIn.value) {
        context.go('/');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UpdateRequiredPage(
      forceUpdateOnPageEnter: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/splash_screen.json',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 24),
              const Text(
                "Aplikasiku",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Memuat data...",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              const AppLoadingWidget(
                message: 'Loading...',
                type: LoadingType.pulse,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
