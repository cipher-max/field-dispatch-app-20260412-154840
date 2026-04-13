class Invoice {
  Invoice({
    required this.id,
    required this.jobId,
    required this.customerName,
    required this.amountCents,
    this.amountPaidCents = 0,
    this.documentType = 'invoice',
    this.paymentLinkUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String jobId;
  final String customerName;
  final int amountCents;
  final int amountPaidCents;
  final String documentType; // estimate, invoice
  final String? paymentLinkUrl;
  final String status; // draft, sent, approved, declined, partial, paid
  final DateTime createdAt;
  final DateTime? updatedAt;

  int get amountDueCents =>
      (amountCents - amountPaidCents).clamp(0, amountCents);

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: (map['id'] ?? '').toString(),
      jobId: (map['job_id'] ?? map['jobId'] ?? '').toString(),
      customerName: (map['customer_name'] ?? map['customerName'] ?? '')
          .toString(),
      amountCents: (map['amount_cents'] ?? map['amountCents'] ?? 0) as int,
      amountPaidCents:
          (map['amount_paid_cents'] ?? map['amountPaidCents'] ?? 0) as int,
      documentType: (map['document_type'] ?? map['documentType'] ?? 'invoice')
          .toString(),
      paymentLinkUrl: (map['payment_link_url'] ?? map['paymentLinkUrl'])
          ?.toString(),
      status: (map['status'] ?? 'draft').toString(),
      createdAt:
          DateTime.tryParse(
            (map['created_at'] ?? map['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
        (map['updated_at'] ?? map['updatedAt'] ?? '').toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'customer_name': customerName,
      'amount_cents': amountCents,
      'amount_paid_cents': amountPaidCents,
      'document_type': documentType,
      'payment_link_url': paymentLinkUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? status,
    int? amountCents,
    int? amountPaidCents,
    String? documentType,
    String? paymentLinkUrl,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id,
      jobId: jobId,
      customerName: customerName,
      amountCents: amountCents ?? this.amountCents,
      amountPaidCents: amountPaidCents ?? this.amountPaidCents,
      documentType: documentType ?? this.documentType,
      paymentLinkUrl: paymentLinkUrl ?? this.paymentLinkUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
