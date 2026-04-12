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

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: (map['id'] ?? '').toString(),
      customerName: (map['customer_name'] ?? map['customerName'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      jobType: (map['job_type'] ?? map['jobType'] ?? '').toString(),
      status: (map['status'] ?? 'new').toString(),
      priority: (map['priority'] ?? 'normal').toString(),
      notes: map['notes']?.toString(),
      technicianName: map['technician_name']?.toString(),
      etaWindow: map['eta_window']?.toString(),
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
    );
  }
}
