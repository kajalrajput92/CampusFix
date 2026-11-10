import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'complaint_models.dart';

final studentComplaintRepositoryProvider = Provider<StudentComplaintRepository>(
  (ref) => StudentComplaintRepository(ref.watch(apiClientProvider)),
);
final complaintImageBytesProvider = FutureProvider.autoDispose.family<Uint8List, int>(
  (ref, imageId) => ref.watch(studentComplaintRepositoryProvider).complaintImage(imageId),
);

class StudentComplaintRepository {
  final ApiClient _api;
  StudentComplaintRepository(this._api);

  dynamic _data(dynamic response) {
    final body = response.data;
    if (body is Map && body['success'] == true && body.containsKey('data')) {
      return body['data'];
    }
    if (body is Map && body['success'] == false) {
      throw ApiException(message: body['message']?.toString() ?? 'The server rejected the request.');
    }
    throw const ApiException(message: 'The server returned an unexpected response.');
  }

  List<dynamic> _list(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value;
    throw const ApiException(message: 'The server returned an invalid list response.');
  }

  Future<List<ComplaintRecord>> myComplaints() async => _list(_data(await _api.get(ApiEndpoints.myComplaints))).map((e) => ComplaintRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();

  Future<ComplaintRecord> complaintDetails(int id) async {
    final payload = Map<String, dynamic>.from(_data(await _api.get(ApiEndpoints.complaintDetails, queryParameters: {'id': id})) as Map);
    final record = ComplaintRecord.fromJson(Map<String, dynamic>.from(payload['complaint'] as Map));
    return ComplaintRecord(id: record.id, number: record.number, title: record.title, status: record.status, category: record.category, priority: record.priority, createdAt: record.createdAt, description: record.description, location: record.location, resolutionNotes: record.resolutionNotes, assignedAt: record.assignedAt,
      images: _list(payload['images']).map((e) => ComplaintImage.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      history: _list(payload['status_history']).map((e) => ComplaintStatusEvent.fromJson(Map<String, dynamic>.from(e as Map))).toList());
  }

  Future<Uint8List> complaintImage(int imageId) async {
    final response = await _api.get<List<int>>(
      ApiEndpoints.complaintImage,
      queryParameters: {'id': imageId},
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const ApiException(message: 'Image is unavailable.');
    }
    return Uint8List.fromList(bytes);
  }

  Future<List<CatalogOption>> departments() async => _list(_data(await _api.get(ApiEndpoints.departments))).map((e) => CatalogOption.department(Map<String, dynamic>.from(e as Map))).toList();
  Future<List<CatalogOption>> locations() async => _list(_data(await _api.get(ApiEndpoints.locations))).map((e) => CatalogOption.location(Map<String, dynamic>.from(e as Map))).toList();

  Future<void> submit({required String title, required String description, required String category, required int locationId, int? departmentId, required List<XFile> images}) async {
    final fields = <String, dynamic>{'title': title.trim(), 'description': description.trim(), 'category': category.trim(), 'location_id': locationId};
    if (departmentId != null) fields['department_id'] = departmentId;
    if (images.isNotEmpty) fields['images'] = await Future.wait(images.map((image) async => MultipartFile.fromFile(image.path, filename: image.name)));
    await _api.post(ApiEndpoints.complaints, data: FormData.fromMap(fields));
  }

  Future<List<StudentFeedback>> myFeedback() async => _list(_data(await _api.get(ApiEndpoints.myFeedback))).map((e) => StudentFeedback.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  Future<void> submitFeedback(int complaintId, int rating, String comments) async => _api.post(ApiEndpoints.feedback, data: {'complaint_id': complaintId, 'rating': rating, if (comments.trim().isNotEmpty) 'comments': comments.trim()});

  Future<List<StudentNotification>> notifications() async {
    const pageSize = 100;
    final all = <StudentNotification>[];
    var page = 1;
    while (true) {
      final pageItems = _list(
        _data(
          await _api.get(
            ApiEndpoints.notifications,
            queryParameters: {'page': page, 'limit': pageSize},
          ),
        ),
      );
      all.addAll(
        pageItems.map(
          (item) => StudentNotification.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
      if (pageItems.length < pageSize) return all;
      page++;
    }
  }
  Future<void> markNotificationRead(int id) async => _api.patch(ApiEndpoints.markNotificationRead, queryParameters: {'notification_id': id});
}
