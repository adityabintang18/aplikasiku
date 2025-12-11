import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/initial_binding.dart';
import 'app/controllers/auth_controller.dart';
import 'app/core/services/update_handler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Lock orientation to portrait only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await dotenv.load(fileName: "lib/.env");

    // Debug: Log environment variables
    debugPrint('Environment variables loaded:');
    debugPrint('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
    debugPrint('APP_VERSION: ${dotenv.env['APP_VERSION']}');

    // Verify required environment variables
    if (dotenv.env['API_BASE_URL'] == null ||
        dotenv.env['API_BASE_URL']!.isEmpty) {
      debugPrint('ERROR: API_BASE_URL not found in .env file');
      debugPrint('Available keys: ${dotenv.env.keys.toList()}');
      throw Exception('API_BASE_URL is required in .env file');
    }

    // Initialize AuthController first for routing
    Get.put(AuthController());

    InitialBinding().dependencies();

    runApp(const ShadAppWithRoutes());
  } catch (e, stackTrace) {
    // If there's an initialization error, show a fallback app
    debugPrint('App initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App failed to start',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your internet connection and try again',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShadAppWithRoutes extends StatelessWidget {
  const ShadAppWithRoutes({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.router(
      title: 'Aplikasiku',
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
      debugShowCheckedModeBanner: false,
      // Wrap with Navigator to enable global dialog access
      builder: (context, child) => Navigator(
        key: navigatorKey,
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) => child!,
          );
        },
      ),
    );
  }
}
