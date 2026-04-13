class Job {
  Job({
    required this.id,
    required this.customerName,
    required this.address,
    required this.jobType,
    required this.status,
    required this.priority,
    this.notes,
    this.technicianName,
    this.etaWindow,
    this.completionNotes,
    this.customerSignatureName,
    this.proofPhotoCount,
    this.proofPhotoUrls,
    this.lastCustomerMessageAt,
    this.customerConfirmedAt,
  });

  final String id;
  final String customerName;
  final String address;
  final String jobType;
  final String status;
  final String priority;
  final String? notes;
  final String? technicianName;
  final String? etaWindow;
  final String? completionNotes;
  final String? customerSignatureName;
  final int? proofPhotoCount;
  final List<String>? proofPhotoUrls;
  final DateTime? lastCustomerMessageAt;
  final DateTime? customerConfirmedAt;

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: (map['id'] ?? '').toString(),
      customerName: (map['customer_name'] ?? map['customerName'] ?? '')
          .toString(),
      address: (map['address'] ?? '').toString(),
      jobType: (map['job_type'] ?? map['jobType'] ?? '').toString(),
      status: (map['status'] ?? 'new').toString(),
      priority: (map['priority'] ?? 'normal').toString(),
      notes: map['notes']?.toString(),
      technicianName: map['technician_name']?.toString(),
      etaWindow: map['eta_window']?.toString(),
      completionNotes: (map['completion_notes'] ?? map['completionNotes'])
          ?.toString(),
      customerSignatureName:
          (map['customer_signature_name'] ?? map['customerSignatureName'])
              ?.toString(),
      proofPhotoCount: map['proof_photo_count'] is num
          ? (map['proof_photo_count'] as num).toInt()
          : (map['proofPhotoCount'] is num
                ? (map['proofPhotoCount'] as num).toInt()
                : null),
      proofPhotoUrls:
          (map['proof_photo_urls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          (map['proofPhotoUrls'] as List?)?.map((e) => e.toString()).toList(),
      lastCustomerMessageAt: DateTime.tryParse(
        (map['last_customer_message_at'] ?? map['lastCustomerMessageAt'] ?? '')
            .toString(),
      ),
      customerConfirmedAt: DateTime.tryParse(
        (map['customer_confirmed_at'] ?? map['customerConfirmedAt'] ?? '')
            .toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'address': address,
      'job_type': jobType,
      'status': status,
      'priority': priority,
      'notes': notes,
      'technician_name': technicianName,
      'eta_window': etaWindow,
      'completion_notes': completionNotes,
      'customer_signature_name': customerSignatureName,
      'proof_photo_count': proofPhotoCount,
      'proof_photo_urls': proofPhotoUrls,
      'last_customer_message_at': lastCustomerMessageAt?.toIso8601String(),
      'customer_confirmed_at': customerConfirmedAt?.toIso8601String(),
    };
  }

  Job copyWith({
    String? customerName,
    String? address,
    String? jobType,
    String? status,
    String? priority,
    String? notes,
    String? technicianName,
    String? etaWindow,
    String? completionNotes,
    String? customerSignatureName,
    int? proofPhotoCount,
    List<String>? proofPhotoUrls,
    DateTime? lastCustomerMessageAt,
    DateTime? customerConfirmedAt,
  }) {
    return Job(
      id: id,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      jobType: jobType ?? this.jobType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      technicianName: technicianName ?? this.technicianName,
      etaWindow: etaWindow ?? this.etaWindow,
      completionNotes: completionNotes ?? this.completionNotes,
      customerSignatureName:
          customerSignatureName ?? this.customerSignatureName,
      proofPhotoCount: proofPhotoCount ?? this.proofPhotoCount,
      proofPhotoUrls: proofPhotoUrls ?? this.proofPhotoUrls,
      lastCustomerMessageAt:
          lastCustomerMessageAt ?? this.lastCustomerMessageAt,
      customerConfirmedAt: customerConfirmedAt ?? this.customerConfirmedAt,
    );
  }
}
