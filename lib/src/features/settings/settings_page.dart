import 'package:flutter/material.dart';

import '../../shared/widgets/shell_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShellScaffold(
      title: 'Settings',
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Environment: Local cache mode (Supabase pending keys)'),
            SizedBox(height: 8),
            Text('MVP notes:'),
            Text('- Plumbing workflow is production-first'),
            Text('- Electrical/HVAC templates are beta'),
            Text('- Invoices are local and status-based for now'),
          ],
        ),
      ),
    );
  }
}
