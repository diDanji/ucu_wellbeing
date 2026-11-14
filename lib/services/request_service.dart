import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/support_request.dart';

/// FR4 - a student sends a support request to one service.
/// The Firestore rules check every field; this class just builds them correctly.
class RequestService {
  RequestService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Saves the request AND its first history entry together (one batch),
  /// so a request never exists without a record of when it was sent.
  /// Returns the new request id.
  Future<String> sendRequest({
    required String serviceId,
    required String requestType,
    required String preferredContact,
    required String contactValue,
    required String urgency,
    String? note,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Please sign in again.');

    // The rules require the name on the request to match the student's profile.
    final profile = await _db.collection('users').doc(user.uid).get();
    final fullName = profile.data()?['fullName'] as String?;
    if (fullName == null) throw StateError('Your profile could not be loaded.');

    final ref = _db.collection('requests').doc();
    final cleanNote = note?.trim() ?? '';
    final batch = _db.batch();
    batch.set(ref, {
      'studentId': user.uid,
      'studentName': fullName,
      'serviceId': serviceId,
      'requestType': requestType,
      'preferredContact': preferredContact,
      'contactValue': contactValue.trim(),
      'urgency': urgency,
      if (cleanNote.isNotEmpty) 'note': cleanNote,
      'status': 'submitted',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastUpdatedBy': user.uid,
    });
    batch.set(ref.collection('updates').doc(), {
      'authorId': user.uid,
      'authorRole': 'student',
      'newStatus': 'submitted',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return ref.id;
  }

  /// The signed-in student's own email, used to pre-fill the form.
  String? get myEmail => _auth.currentUser?.email;

  /// Stream of the student's own requests (used by "My requests" in Task 3).
  /// The where() is required: the rules only allow a student to list their own.
  Stream<List<SupportRequest>> myRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('requests')
        .where('studentId', isEqualTo: uid)
        .snapshots()
        .map((q) {
      final list = q.docs.map(SupportRequest.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }
}
