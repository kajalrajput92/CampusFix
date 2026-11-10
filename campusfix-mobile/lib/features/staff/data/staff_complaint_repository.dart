import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../student/data/complaint_models.dart';
import 'staff_complaint_models.dart';

final staffComplaintRepositoryProvider = Provider<StaffComplaintRepository>(
  (ref) => StaffComplaintRepository(ref.watch(apiClientProvider)),
);

class StaffComplaintRepository {
  final ApiClient _api;

  StaffComplaintRepository(this._api);

  dynamic _data(dynamic response) {
    final body = response.data;
    if (body is Map && body['success'] == true && body.containsKey('data')) {
      return body['data'];
    }
    if (body is Map && body['success'] == false) {
      throw ApiException(
        message:
            body['message']?.toString() ?? 'The server rejected the request.',
      );
    }
    throw const ApiException(
      message: 'The server returned an unexpected response.',
    );
  }

  Future<List<StaffAssignment>> myAssignments() async {
    final value = _data(await _api.get(ApiEndpoints.staffAssignments));
    if (value == null) return const [];
    if (value is! List) {
      throw const ApiException(
        message: 'The server returned an invalid assignment list.',
      );
    }
    return value
        .map(
          (item) =>
              StaffAssignment.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ComplaintRecord> complaintDetails(int complaintId) async {
    final payload = _data(
      await _api.get(
        ApiEndpoints.staffComplaintDetails,
        queryParameters: {'id': complaintId},
      ),
    );
    if (payload is! Map)
      throw const ApiException(message: 'Invalid complaint detail response.');
    final details = Map<String, dynamic>.from(payload);
    final complaintValue = details['complaint'];
    if (complaintValue is! Map)
      throw const ApiException(message: 'Complaint details are missing.');
    final complaint = ComplaintRecord.fromJson(
      Map<String, dynamic>.from(complaintValue),
    );
    List<T> parseList<T>(
      dynamic value,
      T Function(Map<String, dynamic>) parse,
    ) {
      if (value == null) return <T>[];
      if (value is! List)
        throw const ApiException(message: 'Invalid complaint detail list.');
      return value
          .map((item) => parse(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    return ComplaintRecord(
      id: complaint.id,
      number: complaint.number,
      title: complaint.title,
      status: complaint.status,
      category: complaint.category,
      priority: complaint.priority,
      createdAt: complaint.createdAt,
      description: complaint.description,
      location: complaint.location,
      resolutionNotes: complaint.resolutionNotes,
      assignedAt: complaint.assignedAt,
      images: parseList(details['images'], ComplaintImage.fromJson),
      history: parseList(
        details['status_history'],
        ComplaintStatusEvent.fromJson,
      ),
    );
  }

  Future<void> updateStatus({
    required int complaintId,
    required String status,
    String? resolutionNotes,
  }) async {
    await _api.patch(
      ApiEndpoints.staffUpdateStatus,
      data: {
        'complaint_id': complaintId,
        'status': status,
        if (resolutionNotes != null && resolutionNotes.trim().isNotEmpty)
          'resolution_notes': resolutionNotes.trim(),
      },
    );
  }

  Future<List<StudentNotification>> notifications() async {
    const pageSize = 100;
    final result = <StudentNotification>[];
    var page = 1;
    while (true) {
      final value = _data(
        await _api.get(
          ApiEndpoints.notifications,
          queryParameters: {'page': page, 'limit': pageSize},
        ),
      );
      if (value == null) return result;
      if (value is! List) {
        throw const ApiException(
          message: 'The server returned an invalid notifications list.',
        );
      }
      result.addAll(
        value.map(
          (item) => StudentNotification.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
      if (value.length < pageSize) return result;
      page++;
    }
  }

  Future<void> markNotificationRead(int notificationId) async {
    await _api.patch(
      ApiEndpoints.markNotificationRead,
      queryParameters: {'notification_id': notificationId},
    );
  }
}
