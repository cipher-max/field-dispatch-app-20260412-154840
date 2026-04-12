import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Field Dispatch MVP')),
            ListTile(title: const Text('Dashboard'), onTap: () => context.go('/')),
            ListTile(title: const Text('Jobs'), onTap: () => context.go('/jobs')),
            ListTile(title: const Text('Dispatch'), onTap: () => context.go('/dispatch')),
            ListTile(title: const Text('Customers'), onTap: () => context.go('/customers')),
            ListTile(title: const Text('Invoices'), onTap: () => context.go('/invoices')),
            ListTile(title: const Text('Settings'), onTap: () => context.go('/settings')),
          ],
        ),
      ),
      body: child,
    );
  }
}
