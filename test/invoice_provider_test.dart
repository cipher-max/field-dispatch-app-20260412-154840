import 'package:app/src/features/invoices/invoice_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('create estimate, convert, and record partial/full payment', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(invoiceProvider.future);
    final notifier = container.read(invoiceProvider.notifier);

    await notifier.createEstimate(
      jobId: 'job-1',
      customerName: 'Acme Co',
      amountCents: 20000,
    );

    var docs = container.read(invoiceProvider).value!;
    expect(docs.length, 1);
    expect(docs.first.documentType, 'estimate');
    expect(docs.first.status, 'sent');

    await notifier.convertEstimateToInvoice(docs.first.id);
    docs = container.read(invoiceProvider).value!;
    expect(docs.first.documentType, 'invoice');
    expect(docs.first.status, 'draft');

    await notifier.recordPayment(invoiceId: docs.first.id, paymentCents: 5000);
    docs = container.read(invoiceProvider).value!;
    expect(docs.first.amountPaidCents, 5000);
    expect(docs.first.amountDueCents, 15000);
    expect(docs.first.status, 'partial');

    await notifier.recordPayment(invoiceId: docs.first.id, paymentCents: 15000);
    docs = container.read(invoiceProvider).value!;
    expect(docs.first.amountPaidCents, 20000);
    expect(docs.first.amountDueCents, 0);
    expect(docs.first.status, 'paid');
  });

  test('duplicate document creation by job is blocked', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(invoiceProvider.future);
    final notifier = container.read(invoiceProvider.notifier);

    await notifier.createInvoice(
      jobId: 'job-2',
      customerName: 'Bravo LLC',
      amountCents: 10000,
    );

    expect(
      () => notifier.createEstimate(
        jobId: 'job-2',
        customerName: 'Bravo LLC',
        amountCents: 9000,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
