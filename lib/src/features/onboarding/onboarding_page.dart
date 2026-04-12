import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/trades/trade_provider.dart';
import '../../core/trades/trade_type.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your trade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: TradeType.values.map((trade) {
          return Card(
            child: ListTile(
              title: Text(trade.label),
              subtitle: Text(trade.isBeta ? 'Beta template' : 'Production-ready template'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ref.read(selectedTradeProvider.notifier).setTrade(trade);
                context.go('/');
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
