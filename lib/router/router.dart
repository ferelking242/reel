import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';
import '../features/connect/connect_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/live/live_multi_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/search/search_screen.dart';
import '../splash_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      pageBuilder: (context, state) => _fadePage(
        state,
        const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/',
      name: 'feed',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: FeedScreen(),
      ),
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      pageBuilder: (context, state) => _fadePage(
        state,
        const SearchScreen(),
      ),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      pageBuilder: (context, state) => _slidePage(
        state,
        const ProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/friends',
      name: 'friends',
      pageBuilder: (context, state) => _slidePage(
        state,
        const FriendsScreen(),
      ),
    ),
    GoRoute(
      path: '/inbox',
      name: 'inbox',
      pageBuilder: (context, state) => _slidePage(
        state,
        const InboxScreen(),
      ),
    ),
    GoRoute(
      path: '/live',
      name: 'live',
      pageBuilder: (context, state) => _slidePage(
        state,
        const LiveMultiScreen(),
      ),
    ),
    GoRoute(
      path: '/connect',
      name: 'connect',
      pageBuilder: (context, state) => _slidePage(
        state,
        const ConnectScreen(),
      ),
    ),
  ],
);

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: durationNormal,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: ReelCurves.decelerate,
        ),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: durationSlow,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: ReelCurves.emphasized,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
