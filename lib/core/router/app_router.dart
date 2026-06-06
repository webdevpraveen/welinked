import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:welinked/features/auth/presentation/providers/auth_providers.dart';
import 'package:welinked/features/auth/presentation/screens/splash_screen.dart';
import 'package:welinked/features/auth/presentation/screens/login_screen.dart';
import 'package:welinked/features/auth/presentation/screens/register_screen.dart';
import 'package:welinked/features/pairing/presentation/screens/pairing_screen.dart';
import 'package:welinked/features/alerts/presentation/screens/home_screen.dart';
import 'package:welinked/features/alerts/presentation/screens/alert_history_screen.dart';
import 'package:welinked/features/location/presentation/screens/location_screen.dart';
import 'package:welinked/features/settings/presentation/screens/settings_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

enum AuthRoutingState {
  loading,
  loggedOut,
  unpaired,
  paired,
}

final authRoutingStateProvider = Provider<AuthRoutingState>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return AuthRoutingState.loggedOut;
      return user.isPaired ? AuthRoutingState.paired : AuthRoutingState.unpaired;
    },
    error: (_, __) => AuthRoutingState.loggedOut,
    loading: () => AuthRoutingState.loading,
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthRoutingState>(
      authRoutingStateProvider,
      (previous, next) {
        if (previous != next) {
          notifyListeners();
        }
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Application routing layout. Automatically routes using reactive auth status.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pairing',
        builder: (context, state) => const PairingScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => const NoTransitionPage(child: AlertHistoryScreen()),
          ),
          GoRoute(
            path: '/location',
            pageBuilder: (context, state) => const NoTransitionPage(child: LocationScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final routingState = ref.read(authRoutingStateProvider);

      if (routingState == AuthRoutingState.loading) {
        return null;
      }

      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (routingState == AuthRoutingState.loggedOut) {
        return loggingIn ? null : '/login';
      }

      if (routingState == AuthRoutingState.unpaired) {
        return '/pairing';
      }

      // Logged in and paired
      if (routingState == AuthRoutingState.paired) {
        if (loggingIn || state.matchedLocation == '/pairing' || state.matchedLocation == '/splash') {
          return '/home';
        }
      }

      return null;
    },
  );
});

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/home') return 0;
    if (location == '/history') return 1;
    if (location == '/location') return 2;
    if (location == '/settings') return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        context.go('/location');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (idx) => _onItemTapped(idx, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
