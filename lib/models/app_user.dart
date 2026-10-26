import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles used across the system (FR9).
/// - student: self-registers, browses services, sends requests
/// - staff:   works for ONE support service and sees only its requests
/// - admin:   manages accounts and assigns roles
enum UserRole { student, staff, admin }

UserRole roleFromString(String? value) {
  switch (value) {
    case 'staff':
      return UserRole.staff;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.student;
  }
}

/// The support services a staff member can be assigned to.
/// (In Sprint 2 these come from the `services` collection; the IDs stay the same.)
const Map<String, String> kServices = {
  'counselling': 'Counselling',
  'peer_counselling': 'Peer counselling',
  'chaplaincy': 'Chaplaincy',
  'workshops': 'Workshops & talks',
};

/// The profile stored at users/{uid}.
/// Kept deliberately small: no health, mood or counselling data lives here.
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final String? serviceId; // only for staff
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.serviceId,
    this.createdAt,
  });

  String get serviceName => kServices[serviceId] ?? 'No service assigned';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      fullName: (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: roleFromString(data['role'] as String?),
      serviceId: data['serviceId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
