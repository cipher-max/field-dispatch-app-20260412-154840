import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/customers/customers_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/dispatch/dispatch_page.dart';
import 'features/invoices/invoices_page.dart';
import 'features/jobs/jobs_page.dart';
import 'features/settings/settings_page.dart';
import 'features/onboarding/onboarding_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
      GoRoute(path: '/jobs', builder: (context, state) => const JobsPage()),
      GoRoute(path: '/dispatch', builder: (context, state) => const DispatchPage()),
      GoRoute(path: '/customers', builder: (context, state) => const CustomersPage()),
      GoRoute(path: '/invoices', builder: (context, state) => const InvoicesPage()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
    ],
  );
});

class FieldDispatchApp extends ConsumerWidget {
  const FieldDispatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Field Dispatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      routerConfig: router,
    );
  }
}
