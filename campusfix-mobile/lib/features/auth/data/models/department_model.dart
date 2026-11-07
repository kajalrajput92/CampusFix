import 'package:flutter/foundation.dart';

/// Representation of a Department catalog item in CampusFix.
@immutable
class DepartmentModel {
  final int departmentId;
  final String departmentName;
  final String departmentCode;
  final String? description;
  final bool isActive;

  const DepartmentModel({
    required this.departmentId,
    required this.departmentName,
    required this.departmentCode,
    this.description,
    this.isActive = true,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      departmentId: json['department_id'] is int
          ? json['department_id'] as int
          : int.tryParse(json['department_id'].toString()) ?? 0,
      departmentName: json['department_name'] as String? ?? '',
      departmentCode: json['department_code'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'department_id': departmentId,
      'department_name': departmentName,
      'department_code': departmentCode,
      'description': description,
      'is_active': isActive ? 1 : 0,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentModel &&
          runtimeType == other.runtimeType &&
          departmentId == other.departmentId &&
          departmentCode == other.departmentCode;

  @override
  int get hashCode => departmentId.hashCode ^ departmentCode.hashCode;

  @override
  String toString() => '$departmentName ($departmentCode)';
}
