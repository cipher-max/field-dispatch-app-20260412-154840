import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trade_type.dart';
import 'trade_workflow.dart';

class SelectedTradeNotifier extends Notifier<TradeType?> {
  @override
  TradeType? build() => null;

  void setTrade(TradeType trade) => state = trade;
}

final selectedTradeProvider =
    NotifierProvider<SelectedTradeNotifier, TradeType?>(
      SelectedTradeNotifier.new,
    );

final selectedWorkflowProvider = Provider<TradeWorkflow?>((ref) {
  final trade = ref.watch(selectedTradeProvider);
  if (trade == null) return null;
  return workflowFor(trade);
});
