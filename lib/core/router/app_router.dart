import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/view/onboarding_page.dart';
import 'routes.dart';

/// 全局路由。
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.onboarding,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
    ],
  );
});
