import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:aplikasiku/app/controllers/auth_controller.dart';
import 'package:aplikasiku/app/ui/pages/login_page.dart';
import 'package:aplikasiku/app/ui/pages/register_page.dart';
import 'package:aplikasiku/app/ui/pages/transaction_page.dart';
import 'package:aplikasiku/app/ui/pages/main_page.dart';
import 'package:aplikasiku/app/ui/pages/home_page.dart';
import 'package:aplikasiku/app/ui/pages/statistic_page.dart';
import 'package:aplikasiku/app/ui/pages/profile_page.dart';
import 'package:aplikasiku/app/ui/pages/transaction_detail_page.dart';
import 'package:aplikasiku/app/ui/pages/splash_page.dart';
import 'package:aplikasiku/app/data/models/financial_model.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      if (!isDisposed) notifyListeners();
    });
  }
  late final StreamSubscription<dynamic> _subscription;
  bool isDisposed = false;
  @override
  void dispose() {
    isDisposed = true;
    _subscription.cancel();
    super.dispose();
  }
}

// Lazy router that will be created when first accessed
GoRouter? _router;

/// Get the router instance, creating it if necessary
GoRouter get router {
  _router ??= _createRouter();
  return _router!;
}

/// Create the router after AuthController is initialized
GoRouter _createRouter() {
  // Ensure AuthController is available
  AuthController? authC;
  try {
    authC = Get.find<AuthController>();
  } catch (e) {
    // If AuthController is not found, create it
    authC = Get.put(AuthController());
  }

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authC!.isLoggedIn.stream),
    redirect: (context, state) {
      try {
        final loggedIn = authC!.isLoggedIn.value;
        final loggingIn = state.matchedLocation == '/login';
        final registering = state.matchedLocation == '/register';
        final splashing = state.matchedLocation == '/splash';

        if (!loggedIn && !loggingIn && !registering && !splashing)
          return '/login';
        if (loggedIn && (loggingIn || registering)) return '/';
        return null;
      } catch (e) {
        // If there's any error in redirect logic, default to splash
        return '/splash';
      }
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return MainPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) =>
                    HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transaction',
                builder: (BuildContext context, GoRouterState state) =>
                    TransactionPage(),
              ),
              GoRoute(
                path: '/transaction-detail',
                builder: (BuildContext context, GoRouterState state) {
                  final transaction = state.extra as FinansialModel?;
                  if (transaction == null) {
                    // Fallback if no transaction passed
                    return Scaffold(
                      body: Center(child: Text('Transaction not found')),
                    );
                  }
                  return TransactionDetailPage(transaction: transaction);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistic',
                builder: (BuildContext context, GoRouterState state) =>
                    StatisticPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (BuildContext context, GoRouterState state) =>
                    ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => RegisterPage()),
      GoRoute(path: '/splash', builder: (context, state) => SplashPage()),
    ],
  );
}
