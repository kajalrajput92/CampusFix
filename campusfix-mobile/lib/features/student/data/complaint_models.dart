class ComplaintRecord {
  final int id;
  final String number, title, status, category, priority, createdAt;
  final String? description, location, resolutionNotes, assignedAt;
  final List<ComplaintImage> images;
  final List<ComplaintStatusEvent> history;
  final StudentFeedback? feedback;

  const ComplaintRecord({
    required this.id,
    required this.number,
    required this.title,
    required this.status,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.description,
    this.location,
    this.resolutionNotes,
    this.assignedAt,
    this.images = const [],
    this.history = const [],
    this.feedback,
  });

  String get complaintNumber => number;

  factory ComplaintRecord.fromJson(Map<String, dynamic> j) => ComplaintRecord(
    id: _int(j['complaint_id']),
    number: '${j['complaint_number'] ?? '#${j['complaint_id'] ?? ''}'}',
    title: '${j['title'] ?? 'Complaint'}',
    status: '${j['status'] ?? 'SUBMITTED'}',
    category: '${j['category'] ?? ''}',
    priority: '${j['priority'] ?? ''}',
    createdAt: '${j['created_at'] ?? ''}',
    description: j['description']?.toString(),
    resolutionNotes: j['resolution_notes']?.toString(),
    assignedAt: j['assigned_at']?.toString(),
    location: [
      j['building_name'],
      j['block_name'],
      j['floor_number'],
      j['room_number'],
    ].where((x) => x != null && '$x'.isNotEmpty).join(', '),
  );
}

class ComplaintImage {
  final int id;
  final String path;
  const ComplaintImage({this.id = 0, required this.path});
  factory ComplaintImage.fromJson(Map<String, dynamic> j) =>
      ComplaintImage(id: _int(j['image_id']), path: '${j['image_path'] ?? ''}');
}

class ComplaintStatusEvent {
  final String? from;
  final String to, remarks, changedAt;
  const ComplaintStatusEvent({
    this.from,
    required this.to,
    required this.remarks,
    required this.changedAt,
  });
  factory ComplaintStatusEvent.fromJson(Map<String, dynamic> j) =>
      ComplaintStatusEvent(
        from: j['old_status']?.toString(),
        to: '${j['new_status'] ?? ''}',
        remarks: '${j['remarks'] ?? ''}',
        changedAt: '${j['changed_at'] ?? ''}',
      );
}

class StudentFeedback {
  final int complaintId;
  final int rating;
  final String? comments;
  const StudentFeedback({
    required this.complaintId,
    required this.rating,
    this.comments,
  });
  factory StudentFeedback.fromJson(Map<String, dynamic> j) => StudentFeedback(
    complaintId: _int(j['complaint_id']),
    rating: _int(j['rating']),
    comments: j['comments']?.toString(),
  );
}

class StudentNotification {
  final int id;
  final int? complaintId;
  final String title, message, createdAt;
  final bool isRead;
  const StudentNotification({
    required this.id,
    this.complaintId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });
  factory StudentNotification.fromJson(Map<String, dynamic> j) =>
      StudentNotification(
        id: _int(j['notification_id']),
        complaintId: j['complaint_id'] == null ? null : _int(j['complaint_id']),
        title: '${j['title'] ?? ''}',
        message: '${j['message'] ?? ''}',
        createdAt: '${j['created_at'] ?? ''}',
        isRead:
            j['is_read'] == true || j['is_read'] == 1 || j['is_read'] == '1',
      );
}

class CatalogOption {
  final int id;
  final String label;
  const CatalogOption(this.id, this.label);
  factory CatalogOption.department(Map<String, dynamic> j) =>
      CatalogOption(_int(j['department_id']), '${j['department_name'] ?? ''}');
  factory CatalogOption.location(Map<String, dynamic> j) => CatalogOption(
    _int(j['location_id']),
    [
      j['building_name'],
      j['block_name'],
      j['floor_number'] == null ? null : 'Floor ${j['floor_number']}',
      j['room_number'] == null ? null : 'Room ${j['room_number']}',
    ].where((x) => x != null && '$x'.isNotEmpty).join(' · '),
  );
}

int _int(dynamic value) => int.tryParse('$value') ?? 0;
