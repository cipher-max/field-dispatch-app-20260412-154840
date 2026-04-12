import 'package:app/src/features/dispatch/dispatch_eta_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildEtaPresets provides quick, consistent ETA windows', () {
    final now = DateTime(2026, 4, 12, 14, 23);

    final presets = buildEtaPresets(now);

    expect(presets.first, 'ASAP');
    expect(
      presets,
      containsAll([
        '2:45 PM-3:45 PM',
        '3:45 PM-4:45 PM',
        '4:45 PM-5:45 PM',
        'Tomorrow AM (8:00 AM-10:00 AM)',
        'Tomorrow PM (1:00 PM-4:00 PM)',
      ]),
    );
  });
}
