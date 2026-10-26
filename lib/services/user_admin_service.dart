import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// FR9 – admin-only account management. The Firestore rules enforce the
/// same limits on the server, so this cannot be bypassed from a modified app.
class UserAdminService {
  UserAdminService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  Stream<List<AppUser>> allUsers() {
    return _db
        .collection('users')
        .orderBy('fullName')
        .snapshots()
        .map((q) => q.docs.map(AppUser.fromDoc).toList());
  }

  /// Staff must have a service; other roles must not.
  Future<void> setRole({
    required String uid,
    required UserRole role,
    String? serviceId,
  }) async {
    if (role == UserRole.staff && (serviceId == null || !kServices.containsKey(serviceId))) {
      throw ArgumentError('Choose the service this staff member works for.');
    }
    await _db.collection('users').doc(uid).update({
      'role': role.name,
      'serviceId': role == UserRole.staff ? serviceId : null,
    });
  }
}
