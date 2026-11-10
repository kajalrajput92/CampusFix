import 'dart:convert';
import 'dart:typed_data';

import 'package:campusfix/core/network/api_client.dart';
import 'package:campusfix/core/network/api_exception.dart';
import 'package:campusfix/core/storage/secure_storage_service.dart';
import 'package:campusfix/core/router/app_router.dart';
import 'package:campusfix/core/router/route_constants.dart';
import 'package:campusfix/features/staff/data/staff_complaint_models.dart';
import 'package:campusfix/features/staff/data/staff_complaint_repository.dart';
import 'package:campusfix/features/student/data/complaint_models.dart';
import 'package:campusfix/features/student/data/student_complaint_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'test-jwt';
}

class _JsonAdapter implements HttpClientAdapter {
  final List<({int status, Map<String, dynamic> body})> responses;
  int _nextResponse = 0;
  RequestOptions? lastRequest;
  String? lastRequestBody;

  _JsonAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        <int>[],
        (result, part) => result..addAll(part),
      );
      lastRequestBody = utf8.decode(bytes);
    }

    if (_nextResponse >= responses.length) {
      throw StateError('No stub response remains.');
    }
    final response = responses[_nextResponse++];
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient _client(_JsonAdapter adapter, {void Function()? onSessionExpired}) {
  return ApiClient(
    baseUrl: 'https://campusfix.test/api',
    storageService: _TestStorage(),
    httpClientAdapter: adapter,
    onSessionExpired: onSessionExpired,
  );
}

void main() {
  group('Phase 5 data models', () {
    test('student complaint and notification parse backend values', () {
      final complaint = ComplaintRecord.fromJson({
        'complaint_id': 12,
        'complaint_number': 'CF-000012',
        'title': 'Broken light',
        'category': 'Electrical',
        'priority': 'HIGH',
        'status': 'IN_PROGRESS',
        'created_at': '2026-11-10 10:00:00',
      });
      final notification = StudentNotification.fromJson({
        'notification_id': 7,
        'complaint_id': 12,
        'title': 'Work started',
        'message': 'Staff started work.',
        'created_at': '2026-11-10 10:10:00',
        'is_read': 0,
      });

      expect(complaint.id, 12);
      expect(complaint.status, 'IN_PROGRESS');
      expect(notification.complaintId, 12);
      expect(notification.isRead, isFalse);
    });

    test('staff assignment and only supported status transitions parse', () {
      final assignment = StaffAssignment.fromJson({
        'complaint_id': '4',
        'complaint_number': 'CF-000004',
        'title': 'Leaking tap',
        'description': 'Water is leaking.',
        'category': 'Plumbing',
        'priority': 'MEDIUM',
        'status': 'ASSIGNED',
        'created_at': '2026-11-10 09:00:00',
        'assigned_at': '2026-11-10 09:30:00',
      });

      expect(assignment.complaintId, 4);
      expect(nextStaffComplaintStatus('ASSIGNED'), 'IN_PROGRESS');
      expect(nextStaffComplaintStatus('IN_PROGRESS'), 'RESOLVED');
      expect(nextStaffComplaintStatus('RESOLVED'), isNull);
      expect(validateStaffStatusUpdate('RESOLVED', '  '), isNotNull);
      expect(validateStaffStatusUpdate('RESOLVED', 'Fixed the tap.'), isNull);
      expect(validateStaffStatusUpdate('CLOSED', 'Notes'), isNotNull);
    });
  });

  group('Phase 5 repositories', () {
    test('student complaints parse the authenticated API response', () async {
      final adapter = _JsonAdapter([
        (
          status: 200,
          body: {
            'success': true,
            'data': [
              {
                'complaint_id': 2,
                'complaint_number': 'CF-000002',
                'title': 'Window repair',
                'category': 'Maintenance',
                'priority': 'LOW',
                'status': 'SUBMITTED',
                'created_at': '2026-11-10 08:00:00',
              },
            ],
          },
        ),
      ]);
      final repository = StudentComplaintRepository(_client(adapter));

      final complaints = await repository.myComplaints();

      expect(complaints.single.id, 2);
      expect(adapter.lastRequest?.method, 'GET');
      expect(adapter.lastRequest?.uri.path, '/api/complaints/my');
      expect(adapter.lastRequest?.headers['Authorization'], 'Bearer test-jwt');
    });

    test('staff assignments parse and use the staff-only endpoint', () async {
      final adapter = _JsonAdapter([
        (
          status: 200,
          body: {
            'success': true,
            'data': [
              {
                'complaint_id': 9,
                'complaint_number': 'CF-000009',
                'title': 'Door repair',
                'description': 'Door will not close.',
                'category': 'Carpentry',
                'priority': 'HIGH',
                'status': 'ASSIGNED',
                'created_at': '2026-11-10 07:00:00',
                'assigned_at': '2026-11-10 07:30:00',
              },
            ],
          },
        ),
      ]);
      final repository = StaffComplaintRepository(_client(adapter));

      final assignments = await repository.myAssignments();

      expect(assignments.single.complaintId, 9);
      expect(adapter.lastRequest?.method, 'GET');
      expect(adapter.lastRequest?.uri.path, '/api/staff/complaints/my');
    });

    test('staff status update sends backend fields with PATCH', () async {
      final adapter = _JsonAdapter([
        (
          status: 200,
          body: {'success': true, 'data': {'new_status': 'RESOLVED'}},
        ),
      ]);
      final repository = StaffComplaintRepository(_client(adapter));

      await repository.updateStatus(
        complaintId: 9,
        status: 'RESOLVED',
        resolutionNotes: 'Door closer replaced.',
      );

      expect(adapter.lastRequest?.method, 'PATCH');
      expect(adapter.lastRequest?.uri.path, '/api/staff/complaints/status');
      final body = jsonDecode(adapter.lastRequestBody!) as Map<String, dynamic>;
      expect(body, {
        'complaint_id': 9,
        'status': 'RESOLVED',
        'resolution_notes': 'Door closer replaced.',
      });
    });

    test('staff notifications parse and mark read with query parameter', () async {
      final adapter = _JsonAdapter([
        (
          status: 200,
          body: {
            'success': true,
            'data': [
              {
                'notification_id': 3,
                'complaint_id': 9,
                'title': 'Assignment',
                'message': 'A complaint was assigned.',
                'created_at': '2026-11-10 07:30:00',
                'is_read': 0,
              },
            ],
          },
        ),
        (
          status: 200,
          body: {'success': true, 'data': {'notification_id': 3}},
        ),
      ]);
      final repository = StaffComplaintRepository(_client(adapter));

      final notifications = await repository.notifications();
      expect(notifications.single.isRead, isFalse);
      await repository.markNotificationRead(3);

      expect(adapter.lastRequest?.method, 'PATCH');
      expect(adapter.lastRequest?.uri.path, '/api/notifications/read');
      expect(adapter.lastRequest?.uri.queryParameters['notification_id'], '3');
    });

    test('401 triggers the shared session-expiry callback', () async {
      var expired = false;
      final adapter = _JsonAdapter([
        (
          status: 401,
          body: {'success': false, 'message': 'Unauthorized.'},
        ),
      ]);
      final repository = StaffComplaintRepository(
        _client(adapter, onSessionExpired: () => expired = true),
      );

      await expectLater(
        repository.myAssignments(),
        throwsA(isA<ApiException>().having((error) => error.statusCode, 'statusCode', 401)),
      );
      expect(expired, isTrue);
    });
  });

  group('Role navigation and route guards', () {
    test('each supported role receives a separate landing route', () {
      expect(
        AppRouter.resolveRoleDestination('STUDENT'),
        RouteConstants.studentDashboard,
      );
      expect(
        AppRouter.resolveRoleDestination('STAFF'),
        RouteConstants.staffDashboard,
      );
      expect(
        AppRouter.resolveRoleDestination('ADMIN'),
        RouteConstants.adminDashboard,
      );
    });

    test('deep links cannot cross student, staff, and admin portals', () {
      expect(
        AppRouter.roleGuardRedirect('STUDENT', '/staff/complaints/9'),
        RouteConstants.studentDashboard,
      );
      expect(
        AppRouter.roleGuardRedirect('STAFF', '/student/complaints/new'),
        RouteConstants.staffDashboard,
      );
      expect(
        AppRouter.roleGuardRedirect('ADMIN', '/staff/complaints/9'),
        RouteConstants.adminDashboard,
      );
      expect(
        AppRouter.roleGuardRedirect('STAFF', '/staff/complaints/9'),
        isNull,
      );
    });

    test('unauthenticated deep links return to welcome', () {
      expect(
        AppRouter.redirectForAccess(
          isAuthenticated: false,
          role: null,
          path: '/staff/complaints/9',
        ),
        RouteConstants.welcome,
      );
      expect(
        AppRouter.redirectForAccess(
          isAuthenticated: false,
          role: null,
          path: RouteConstants.login,
        ),
        isNull,
      );
    });
  });
}
