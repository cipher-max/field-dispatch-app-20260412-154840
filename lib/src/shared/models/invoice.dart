class Invoice {
  Invoice({
    required this.id,
    required this.jobId,
    required this.customerName,
    required this.amountCents,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String customerName;
  final int amountCents;
  final String status; // draft, sent, paid
  final DateTime createdAt;

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: (map['id'] ?? '').toString(),
      jobId: (map['job_id'] ?? map['jobId'] ?? '').toString(),
      customerName: (map['customer_name'] ?? map['customerName'] ?? '').toString(),
      amountCents: (map['amount_cents'] ?? map['amountCents'] ?? 0) as int,
      status: (map['status'] ?? 'draft').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? map['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'customer_name': customerName,
      'amount_cents': amountCents,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? status,
    int? amountCents,
  }) {
    return Invoice(
      id: id,
      jobId: jobId,
      customerName: customerName,
      amountCents: amountCents ?? this.amountCents,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
