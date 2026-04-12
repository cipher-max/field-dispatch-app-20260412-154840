import 'trade_type.dart';

class TradeWorkflow {
  const TradeWorkflow({
    required this.trade,
    required this.requiredFields,
    required this.jobTypes,
    required this.checklist,
  });

  final TradeType trade;
  final List<String> requiredFields;
  final List<String> jobTypes;
  final List<String> checklist;
}

const plumbingWorkflow = TradeWorkflow(
  trade: TradeType.plumbing,
  requiredFields: ['Issue type', 'Leak severity', 'Access notes'],
  jobTypes: ['Leak repair', 'Drain clean', 'Water heater', 'Fixture install'],
  checklist: ['Shutoff checked', 'Pressure tested', 'Before/after photos'],
);

const electricalWorkflow = TradeWorkflow(
  trade: TradeType.electrical,
  requiredFields: ['Circuit type', 'Panel notes'],
  jobTypes: ['Outlet repair', 'Breaker replacement', 'Lighting install'],
  checklist: ['Power isolated', 'Load tested', 'Photos attached'],
);

const hvacWorkflow = TradeWorkflow(
  trade: TradeType.hvac,
  requiredFields: ['System type', 'Filter status'],
  jobTypes: ['No cooling', 'No heat', 'Maintenance'],
  checklist: ['Thermostat check', 'Airflow check', 'Photos attached'],
);

TradeWorkflow workflowFor(TradeType trade) {
  switch (trade) {
    case TradeType.plumbing:
      return plumbingWorkflow;
    case TradeType.electrical:
      return electricalWorkflow;
    case TradeType.hvac:
      return hvacWorkflow;
  }
}
