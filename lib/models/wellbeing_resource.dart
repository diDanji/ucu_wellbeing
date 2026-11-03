import 'package:cloud_firestore/cloud_firestore.dart';

/// A piece of wellbeing information (EERD: WELLBEING_RESOURCE), stored at
/// resources/{resourceId}. Students only ever receive PUBLISHED resources.
class WellbeingResource {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String resourceType; // article | guide | ...
  final String? categoryId;
  final String status; // draft | published | archived
  final String? createdBy;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  const WellbeingResource({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.resourceType,
    this.categoryId,
    required this.status,
    this.createdBy,
    this.publishedAt,
    this.updatedAt,
  });

  factory WellbeingResource.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return WellbeingResource(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Untitled',
      summary: (d['summary'] as String?) ?? '',
      content: (d['content'] as String?) ?? '',
      resourceType: (d['resourceType'] as String?) ?? 'article',
      categoryId: d['categoryId'] as String?,
      status: (d['status'] as String?) ?? 'draft',
      createdBy: d['createdBy'] as String?,
      publishedAt: (d['publishedAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
