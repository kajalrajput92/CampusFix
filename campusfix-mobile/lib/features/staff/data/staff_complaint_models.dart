class StaffAssignment {
  final int complaintId;
  final String complaintNumber;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String createdAt;
  final String assignedAt;

  const StaffAssignment({
    required this.complaintId,
    required this.complaintNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.assignedAt,
  });

  factory StaffAssignment.fromJson(Map<String, dynamic> json) {
    return StaffAssignment(
      complaintId: int.tryParse('${json['complaint_id']}') ?? 0,
      complaintNumber: '${json['complaint_number'] ?? ''}',
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      category: '${json['category'] ?? ''}',
      priority: '${json['priority'] ?? ''}',
      status: '${json['status'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      assignedAt: '${json['assigned_at'] ?? ''}',
    );
  }
}

String? nextStaffComplaintStatus(String currentStatus) =>
    switch (currentStatus.toUpperCase()) {
      'ASSIGNED' => 'IN_PROGRESS',
      'IN_PROGRESS' => 'RESOLVED',
      _ => null,
    };

String? validateStaffStatusUpdate(String status, String resolutionNotes) {
  if (status != 'IN_PROGRESS' && status != 'RESOLVED') {
    return 'This status update is not supported.';
  }
  if (status == 'RESOLVED' && resolutionNotes.trim().isEmpty) {
    return 'Resolution notes are required.';
  }
  return null;
}
