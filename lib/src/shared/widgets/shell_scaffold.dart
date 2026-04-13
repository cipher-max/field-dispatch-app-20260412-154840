import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = switch (path) {
      '/' => 0,
      '/jobs' => 1,
      '/dispatch' => 2,
      '/customers' => 3,
      '/invoices' => 4,
      _ => 0,
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Field Dispatch MVP')),
            ListTile(
              title: const Text('Dashboard'),
              onTap: () => context.go('/'),
            ),
            ListTile(
              title: const Text('Jobs'),
              onTap: () => context.go('/jobs'),
            ),
            ListTile(
              title: const Text('Dispatch'),
              onTap: () => context.go('/dispatch'),
            ),
            ListTile(
              title: const Text('Customers'),
              onTap: () => context.go('/customers'),
            ),
            ListTile(
              title: const Text('Invoices'),
              onTap: () => context.go('/invoices'),
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          switch (value) {
            case 0:
              context.go('/');
            case 1:
              context.go('/jobs');
            case 2:
              context.go('/dispatch');
            case 3:
              context.go('/customers');
            case 4:
              context.go('/invoices');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.alt_route), label: 'Dispatch'),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Invoices',
          ),
        ],
      ),
    );
  }
}
