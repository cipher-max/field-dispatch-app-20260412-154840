enum JobPriority { low, normal, high, urgent }

extension JobPriorityX on JobPriority {
  String get value {
    switch (this) {
      case JobPriority.low:
        return 'low';
      case JobPriority.normal:
        return 'normal';
      case JobPriority.high:
        return 'high';
      case JobPriority.urgent:
        return 'urgent';
    }
  }

  String get label {
    switch (this) {
      case JobPriority.low:
        return 'Low';
      case JobPriority.normal:
        return 'Normal';
      case JobPriority.high:
        return 'High';
      case JobPriority.urgent:
        return 'Urgent';
    }
  }

  int get rank {
    switch (this) {
      case JobPriority.urgent:
        return 4;
      case JobPriority.high:
        return 3;
      case JobPriority.normal:
        return 2;
      case JobPriority.low:
        return 1;
    }
  }

  static JobPriority fromValue(String raw) {
    return JobPriority.values.firstWhere(
      (p) => p.value == raw,
      orElse: () => JobPriority.normal,
    );
  }
}
