import '../../shared/models/invoice.dart';

bool invoiceNeedsCollectionFollowUp(Invoice invoice, {DateTime? now}) {
  if (invoice.documentType != 'invoice') return false;
  if (invoice.amountDueCents <= 0) return false;
  if (invoice.status == 'paid') return false;

  final effectiveNow = now ?? DateTime.now();
  final ageDays = effectiveNow.difference(invoice.createdAt).inDays;

  return ageDays >= 7;
}

int invoiceAgeDays(Invoice invoice, {DateTime? now}) {
  final effectiveNow = now ?? DateTime.now();
  return effectiveNow.difference(invoice.createdAt).inDays;
}
