import 'dart:convert';
import 'dart:typed_data';

import 'package:campusfix/core/network/api_client.dart';
import 'package:campusfix/core/storage/secure_storage_service.dart';
import 'package:campusfix/features/student/data/student_complaint_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'test-jwt';
}

class _JsonAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> responses;
  int _responseIndex = 0;
  RequestOptions? lastRequest;
  Object? lastData;
  String? requestBody;

  _JsonAdapter(this.responses);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    lastData = options.data;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
        <int>[],
        (result, part) => result..addAll(part),
      );
      requestBody = utf8.decode(bytes);
    }
    final body = responses[_responseIndex++];
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'student feedback history parses and submission uses backend contract',
    () async {
      final adapter = _JsonAdapter([
        {
          'success': true,
          'data': [
            {
              'feedback_id': 21,
              'complaint_id': 15,
              'rating': 4,
              'comments': 'Resolved well.',
              'created_at': '2026-11-10 10:00:00',
            },
          ],
        },
        {
          'success': true,
          'data': {
            'feedback_id': 22,
            'complaint_id': 16,
            'rating': 5,
            'comments': 'Excellent.',
          },
        },
      ]);
      final client = ApiClient(
        baseUrl: 'https://campusfix.test/api',
        storageService: _TestStorage(),
        httpClientAdapter: adapter,
      );
      final repository = StudentComplaintRepository(client);

      final history = await repository.myFeedback();
      expect(history.single.complaintId, 15);
      expect(history.single.rating, 4);

      await repository.submitFeedback(16, 5, 'Excellent.');
      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.uri.path, '/api/feedback');
      expect(jsonDecode(adapter.requestBody!), {
        'complaint_id': 16,
        'rating': 5,
        'comments': 'Excellent.',
      });
    },
  );

  test('department and location catalogs parse backend records', () async {
    final adapter = _JsonAdapter([
      {
        'success': true,
        'data': [
          {'department_id': 2, 'department_name': 'Facilities'},
        ],
      },
      {
        'success': true,
        'data': [
          {
            'location_id': 8,
            'building_name': 'Library',
            'block_name': 'East',
            'floor_number': 2,
            'room_number': '204',
          },
        ],
      },
    ]);
    final repository = StudentComplaintRepository(
      ApiClient(
        baseUrl: 'https://campusfix.test/api',
        storageService: _TestStorage(),
        httpClientAdapter: adapter,
      ),
    );

    final departments = await repository.departments();
    final locations = await repository.locations();
    expect(departments.single.label, 'Facilities');
    expect(locations.single.id, 8);
    expect(locations.single.label, contains('Library'));
  });
}
