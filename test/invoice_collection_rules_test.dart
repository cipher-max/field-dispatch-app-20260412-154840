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

  test('estimateNeedsFollowUp true for stale sent estimate', () {
    final now = DateTime(2026, 4, 13);
    final estimate = Invoice(
      id: 'est-1',
      jobId: 'job-10',
      customerName: 'Delta',
      amountCents: 12000,
      documentType: 'estimate',
      status: 'sent',
      createdAt: now.subtract(const Duration(days: 3)),
    );

    expect(estimateNeedsFollowUp(estimate, now: now), isTrue);
  });

  test('estimateNeedsFollowUp false for approved/declined/recent', () {
    final now = DateTime(2026, 4, 13);
    final approved = Invoice(
      id: 'est-2',
      jobId: 'job-11',
      customerName: 'Echo',
      amountCents: 12000,
      documentType: 'estimate',
      status: 'approved',
      createdAt: now.subtract(const Duration(days: 5)),
    );
    final declined = Invoice(
      id: 'est-3',
      jobId: 'job-12',
      customerName: 'Foxtrot',
      amountCents: 12000,
      documentType: 'estimate',
      status: 'declined',
      createdAt: now.subtract(const Duration(days: 5)),
    );
    final recent = Invoice(
      id: 'est-4',
      jobId: 'job-13',
      customerName: 'Golf',
      amountCents: 12000,
      documentType: 'estimate',
      status: 'sent',
      createdAt: now.subtract(const Duration(hours: 20)),
    );

    expect(estimateNeedsFollowUp(approved, now: now), isFalse);
    expect(estimateNeedsFollowUp(declined, now: now), isFalse);
    expect(estimateNeedsFollowUp(recent, now: now), isFalse);
  });
}
