import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/support_service.dart';
import '../models/wellbeing_resource.dart';

/// FR6 - staff keep service information and wellbeing resources up to date.
/// The Firestore rules decide what each staff member may change:
/// only THEIR OWN service, and only resources THEY created.
class StaffContentService {
  StaffContentService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  // ---------- services ----------
  Future<SupportService?> loadService(String serviceId) async {
    final doc = await _db.collection('services').doc(serviceId).get();
    return doc.exists ? SupportService.fromDoc(doc) : null;
  }

  Future<void> updateService({
    required String serviceId,
    required String editorUid,
    required Map<String, dynamic> fields,
  }) {
    return _db.collection('services').doc(serviceId).update({
      ...fields,
      'updatedBy': editorUid, // the rules require this to be the signed-in user
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- resources ----------
  /// Staff may see every resource, including drafts, so no status filter here.
  Stream<List<WellbeingResource>> allResources() {
    return _db.collection('resources').snapshots().map((q) {
      final list = q.docs.map(WellbeingResource.fromDoc).toList();
      list.sort((a, b) {
        final ad = a.updatedAt, bd = b.updatedAt;
        if (ad != null && bd != null) return bd.compareTo(ad);
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return list;
    });
  }

  Future<WellbeingResource?> loadResource(String id) async {
    final doc = await _db.collection('resources').doc(id).get();
    return doc.exists ? WellbeingResource.fromDoc(doc) : null;
  }

  Future<void> createResource({
    required String authorUid,
    required String title,
    required String summary,
    required String content,
    required String resourceType,
    required String categoryId,
    required String status,
  }) {
    return _db.collection('resources').add({
      'title': title,
      'summary': summary,
      'content': content,
      'resourceType': resourceType,
      'categoryId': categoryId,
      'status': status,
      'createdBy': authorUid, // the rules require this to be the signed-in user
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'published') 'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateResource({
    required WellbeingResource original,
    required String title,
    required String summary,
    required String content,
    required String resourceType,
    required String categoryId,
    required String status,
  }) {
    return _db.collection('resources').doc(original.id).update({
      'title': title,
      'summary': summary,
      'content': content,
      'resourceType': resourceType,
      'categoryId': categoryId,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'published' && original.status != 'published') 'publishedAt': FieldValue.serverTimestamp(),
    });
  }
}
