enum TradeType { plumbing, electrical, hvac }

extension TradeTypeX on TradeType {
  String get label {
    switch (this) {
      case TradeType.plumbing:
        return 'Plumbing';
      case TradeType.electrical:
        return 'Electrical';
      case TradeType.hvac:
        return 'HVAC';
    }
  }

  bool get isBeta => this != TradeType.plumbing;
}
