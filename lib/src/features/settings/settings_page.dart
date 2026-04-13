import 'package:flutter/material.dart';

import '../../core/config/app_env.dart';
import '../../shared/widgets/shell_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      title: 'Settings',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Environment: Local cache mode (Supabase pending keys)'),
            const SizedBox(height: 8),
            const Text('Integrations:'),
            Text(
              '• Stripe payment links: '
              '${AppEnv.hasStripeLinkBase ? 'Configured' : 'Missing STRIPE_PAYMENT_LINK_BASE_URL'}',
            ),
            Text(
              '• QuickBooks OAuth app: '
              '${AppEnv.hasQuickBooksClientId ? 'Configured' : 'Missing QUICKBOOKS_CLIENT_ID'}',
            ),
            const SizedBox(height: 8),
            const Text('MVP notes:'),
            const Text('- Plumbing workflow is production-first'),
            const Text('- Electrical/HVAC templates are beta'),
            const Text(
              '- Invoices support estimate/invoice + partial payments',
            ),
            const Text('- QuickBooks CSV export works now (share sheet)'),
          ],
        ),
      ),
    );
  }
}
