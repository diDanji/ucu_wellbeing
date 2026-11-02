import 'package:cloud_firestore/cloud_firestore.dart';

/// One entry in the service directory (EERD: SUPPORT_SERVICE), stored at
/// services/{serviceId}. Students only ever receive PUBLISHED services.
class SupportService {
  final String id;
  final String name;
  final String description;
  final String? categoryId;
  final String? location;
  final String? operatingHours;
  final String? contactMethod;
  final String? accessMethod;
  final String? eligibility;
  final String? whatToExpect;
  final bool appointmentRequired;
  final String? expectedResponseTime;
  final String status;
  final DateTime? updatedAt;

  const SupportService({
    required this.id,
    required this.name,
    required this.description,
    this.categoryId,
    this.location,
    this.operatingHours,
    this.contactMethod,
    this.accessMethod,
    this.eligibility,
    this.whatToExpect,
    required this.appointmentRequired,
    this.expectedResponseTime,
    required this.status,
    this.updatedAt,
  });

  factory SupportService.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SupportService(
      id: doc.id,
      name: (d['name'] as String?) ?? doc.id,
      description: (d['description'] as String?) ?? '',
      categoryId: d['categoryId'] as String?,
      location: d['location'] as String?,
      operatingHours: d['operatingHours'] as String?,
      contactMethod: d['contactMethod'] as String?,
      accessMethod: d['accessMethod'] as String?,
      eligibility: d['eligibility'] as String?,
      whatToExpect: d['whatToExpect'] as String?,
      appointmentRequired: (d['appointmentRequired'] as bool?) ?? false,
      expectedResponseTime: d['expectedResponseTime'] as String?,
      status: (d['status'] as String?) ?? 'draft',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// True when a detail has not been confirmed yet: empty, or a
  /// placeholder such as "[To be confirmed with the service]".
  static bool isMissing(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty || v.startsWith('[');
  }
}
