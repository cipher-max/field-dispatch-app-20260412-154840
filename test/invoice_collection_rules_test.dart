import 'package:app/src/features/invoices/invoice_collection_rules.dart';
import 'package:app/src/shared/models/invoice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'invoiceNeedsCollectionFollowUp true when unpaid invoice is 7+ days old',
    () {
      final now = DateTime(2026, 4, 13);
      final invoice = Invoice(
        id: 'inv-1',
        jobId: 'job-1',
        customerName: 'Acme',
        amountCents: 10000,
        amountPaidCents: 0,
        status: 'sent',
        createdAt: now.subtract(const Duration(days: 8)),
      );

      expect(invoiceNeedsCollectionFollowUp(invoice, now: now), isTrue);
    },
  );

  test('invoiceNeedsCollectionFollowUp false for paid or recent invoices', () {
    final now = DateTime(2026, 4, 13);

    final paid = Invoice(
      id: 'inv-2',
      jobId: 'job-2',
      customerName: 'Bravo',
      amountCents: 10000,
      amountPaidCents: 10000,
      status: 'paid',
      createdAt: now.subtract(const Duration(days: 20)),
    );

    final recent = Invoice(
      id: 'inv-3',
      jobId: 'job-3',
      customerName: 'Charlie',
      amountCents: 10000,
      amountPaidCents: 0,
      status: 'sent',
      createdAt: now.subtract(const Duration(days: 2)),
    );

    expect(invoiceNeedsCollectionFollowUp(paid, now: now), isFalse);
    expect(invoiceNeedsCollectionFollowUp(recent, now: now), isFalse);
  });
}
