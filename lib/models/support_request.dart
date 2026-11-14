import 'package:cloud_firestore/cloud_firestore.dart';

/// A student's request for support from one service (EERD: SUPPORT_REQUEST),
/// stored at requests/{requestId}. History lives in requests/{id}/updates.
class SupportRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String serviceId;
  final String requestType;
  final String preferredContact;
  final String contactValue;
  final String urgency;
  final String? note;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.serviceId,
    required this.requestType,
    required this.preferredContact,
    required this.contactValue,
    required this.urgency,
    this.note,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SupportRequest(
      id: doc.id,
      studentId: (d['studentId'] as String?) ?? '',
      studentName: (d['studentName'] as String?) ?? '',
      serviceId: (d['serviceId'] as String?) ?? '',
      requestType: (d['requestType'] as String?) ?? 'other',
      preferredContact: (d['preferredContact'] as String?) ?? 'email',
      contactValue: (d['contactValue'] as String?) ?? '',
      urgency: (d['urgency'] as String?) ?? 'this_week',
      note: d['note'] as String?,
      status: (d['status'] as String?) ?? 'submitted',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Short reference a student can quote, e.g. "A1B2C3".
  String get reference => id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();

  bool get isUrgent => urgency == 'asap';

  bool get isFinal => status == 'closed' || status == 'withdrawn';
}

/// Plain-language labels. The keys match the values the Firestore rules accept.
const Map<String, String> kRequestTypes = {
  'appointment': 'Book an appointment',
  'talk_to_someone': 'Talk to someone',
  'information': 'Ask for information',
  'other': 'Something else',
};

const Map<String, String> kContactMethods = {
  'call': 'Phone call',
  'sms': 'SMS',
  'email': 'Email',
};

/// How soon the STUDENT says they need help. The app never decides this for them.
const Map<String, String> kUrgencyLevels = {
  'asap': 'As soon as possible',
  'this_week': 'This week',
  'no_rush': 'No rush',
};

const Map<String, String> kRequestStatuses = {
  'submitted': 'Submitted',
  'under_review': 'Under review',
  'info_requested': 'More information needed',
  'contacted': 'Contacted',
  'closed': 'Closed',
  'withdrawn': 'Withdrawn',
};

/// Limits shared with the Firestore rules.
const int kNoteMaxLength = 500;
const int kContactMaxLength = 100;
