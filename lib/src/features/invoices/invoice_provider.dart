import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../shared/models/invoice.dart';

class InvoiceNotifier extends AsyncNotifier<List<Invoice>> {
  static const _cacheKey = 'invoice_cache_v1';
  static const _uuid = Uuid();

  @override
  Future<List<Invoice>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Invoice.fromMap).toList();
  }

  Future<void> createInvoice({
    required String jobId,
    required String customerName,
    required int amountCents,
  }) async {
    final current = state.asData?.value ?? [];
    final alreadyExists = current.any((i) => i.jobId == jobId);
    if (alreadyExists) {
      throw StateError('Invoice already exists for this job.');
    }

    final invoice = Invoice(
      id: _uuid.v4(),
      jobId: jobId,
      customerName: customerName,
      amountCents: amountCents,
      amountPaidCents: 0,
      documentType: 'invoice',
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final next = [invoice, ...current];
    state = AsyncData(next);
    await _write(next);
  }

  Future<void> createEstimate({
    required String jobId,
    required String customerName,
    required int amountCents,
  }) async {
    final current = state.asData?.value ?? [];
    final alreadyExists = current.any((i) => i.jobId == jobId);
    if (alreadyExists) {
      throw StateError('A document already exists for this job.');
    }

    final estimate = Invoice(
      id: _uuid.v4(),
      jobId: jobId,
      customerName: customerName,
      amountCents: amountCents,
      amountPaidCents: 0,
      documentType: 'estimate',
      status: 'sent',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final next = [estimate, ...current];
    state = AsyncData(next);
    await _write(next);
  }

  Future<void> markStatus(String invoiceId, String status) async {
    final current = state.asData?.value ?? [];
    final next = [
      for (final i in current)
        if (i.id == invoiceId)
          i.copyWith(status: status, updatedAt: DateTime.now())
        else
          i,
    ];
    state = AsyncData(next);
    await _write(next);
  }

  Future<void> recordPayment({
    required String invoiceId,
    required int paymentCents,
  }) async {
    final current = state.asData?.value ?? [];
    final next = [
      for (final i in current)
        if (i.id == invoiceId)
          () {
            final paid = (i.amountPaidCents + paymentCents).clamp(
              0,
              i.amountCents,
            );
            final status = paid >= i.amountCents ? 'paid' : 'partial';
            return i.copyWith(
              amountPaidCents: paid,
              status: status,
              updatedAt: DateTime.now(),
            );
          }()
        else
          i,
    ];
    state = AsyncData(next);
    await _write(next);
  }

  Future<void> convertEstimateToInvoice(String invoiceId) async {
    final current = state.asData?.value ?? [];
    final next = [
      for (final i in current)
        if (i.id == invoiceId)
          i.copyWith(
            documentType: 'invoice',
            status: 'draft',
            updatedAt: DateTime.now(),
          )
        else
          i,
    ];
    state = AsyncData(next);
    await _write(next);
  }

  Future<void> _write(List<Invoice> invoices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(invoices.map((i) => i.toMap()).toList()),
    );
  }
}

final invoiceProvider = AsyncNotifierProvider<InvoiceNotifier, List<Invoice>>(
  InvoiceNotifier.new,
);
