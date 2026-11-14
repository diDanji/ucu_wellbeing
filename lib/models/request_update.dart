import 'package:cloud_firestore/cloud_firestore.dart';

/// One entry in a request's history (EERD: REQUEST_UPDATE), stored at
/// requests/{requestId}/updates/{updateId}. Entries are never edited or deleted.
class RequestUpdate {
  final String id;
  final String authorId;
  final String authorRole; // 'student' or 'staff'
  final String? newStatus;
  final String? message;
  final DateTime? createdAt;

  const RequestUpdate({
    required this.id,
    required this.authorId,
    required this.authorRole,
    this.newStatus,
    this.message,
    this.createdAt,
  });

  factory RequestUpdate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return RequestUpdate(
      id: doc.id,
      authorId: (d['authorId'] as String?) ?? '',
      authorRole: (d['authorRole'] as String?) ?? 'staff',
      newStatus: d['newStatus'] as String?,
      message: d['message'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get fromStaff => authorRole == 'staff';
}
