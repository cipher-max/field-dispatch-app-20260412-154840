String _pad2(int value) => value.toString().padLeft(2, '0');

String _formatTime(DateTime dt) {
  final hour = dt.hour;
  final minute = dt.minute;
  final amPm = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$hour12:${_pad2(minute)} $amPm';
}

String _formatWindow(DateTime start, DateTime end) {
  return '${_formatTime(start)}-${_formatTime(end)}';
}

List<String> buildEtaPresets(DateTime now) {
  final rounded = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    (now.minute ~/ 15) * 15,
  );

  final in30 = rounded.add(const Duration(minutes: 30));
  final in90 = rounded.add(const Duration(minutes: 90));
  final in150 = rounded.add(const Duration(minutes: 150));
  final in210 = rounded.add(const Duration(minutes: 210));

  final tomorrowMorningStart = DateTime(now.year, now.month, now.day + 1, 8);
  final tomorrowMorningEnd = DateTime(now.year, now.month, now.day + 1, 10);
  final tomorrowAfternoonStart = DateTime(now.year, now.month, now.day + 1, 13);
  final tomorrowAfternoonEnd = DateTime(now.year, now.month, now.day + 1, 16);

  return [
    'ASAP',
    _formatWindow(in30, in90),
    _formatWindow(in90, in150),
    _formatWindow(in150, in210),
    'Tomorrow AM (${_formatWindow(tomorrowMorningStart, tomorrowMorningEnd)})',
    'Tomorrow PM (${_formatWindow(tomorrowAfternoonStart, tomorrowAfternoonEnd)})',
  ];
}
