import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/models/invoice.dart';

class QuickBooksExportService {
  Future<String> exportInvoicesCsv(List<Invoice> docs) async {
    final dir = await getTemporaryDirectory();
    final filename =
        'quickbooks_invoices_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(p.join(dir.path, filename));

    final invoices = docs.where((d) => d.documentType == 'invoice').toList();

    final lines = <String>[
      'TxnDate,RefNumber,Customer,Amount,AmountPaid,BalanceDue,Status,JobId,InvoiceId',
      ...invoices.map((i) {
        final date = i.createdAt.toIso8601String().split('T').first;
        return _csvRow([
          date,
          i.id,
          i.customerName,
          (i.amountCents / 100).toStringAsFixed(2),
          (i.amountPaidCents / 100).toStringAsFixed(2),
          (i.amountDueCents / 100).toStringAsFixed(2),
          i.status,
          i.jobId,
          i.id,
        ]);
      }),
    ];

    await file.writeAsString(lines.join('\n'));
    return file.path;
  }

  String _csvRow(List<String> fields) {
    return fields.map((f) => '"${f.replaceAll('"', '""')}"').join(',');
  }
}
