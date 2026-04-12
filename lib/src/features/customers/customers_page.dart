import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../jobs/job_provider.dart';
import '../../shared/widgets/shell_scaffold.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);

    return ShellScaffold(
      title: 'Customers',
      child: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load customers: $e')),
        data: (jobs) {
          final map = <String, String>{};
          for (final j in jobs) {
            map[j.customerName] = j.address;
          }
          final customers = map.entries
              .where((e) => e.key.toLowerCase().contains(query.toLowerCase()))
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search customer',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
              const SizedBox(height: 12),
              Text('Customers (${customers.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (customers.isEmpty)
                const Card(child: ListTile(title: Text('No customers yet')))
              else
                ...customers.map(
                  (c) => Card(
                    child: ListTile(
                      title: Text(c.key),
                      subtitle: Text(c.value),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
