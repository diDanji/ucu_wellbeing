import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles used across the system (FR9 builds on this in Task 4).
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

/// The profile stored at users/{uid}.
/// Kept deliberately small: no health, mood or counselling data lives here.
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      fullName: (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: roleFromString(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
