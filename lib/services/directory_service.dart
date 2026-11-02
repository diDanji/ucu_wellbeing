import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_category.dart';
import '../models/support_service.dart';

/// FR3 - reads the service directory for students.
///
/// Firestore rules are not filters: a student's query must ask ONLY for
/// published services (where status == 'published'), otherwise the whole
/// query is refused. That is what makes "students see only published
/// content" true on the server, not just in the app.
class DirectoryService {
  DirectoryService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  Stream<List<SupportService>> publishedServices() {
    return _db
        .collection('services')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((q) {
      final list = q.docs.map(SupportService.fromDoc).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  /// One service. A draft (or unknown) service is refused by the rules,
  /// which arrives here as a stream error.
  Stream<SupportService?> service(String id) {
    return _db.collection('services').doc(id).snapshots().map(
          (doc) => doc.exists ? SupportService.fromDoc(doc) : null,
        );
  }

  /// Active categories, keyed by id.
  Stream<Map<String, ServiceCategory>> activeCategories() {
    return _db.collection('categories').snapshots().map((q) {
      final map = <String, ServiceCategory>{};
      for (final doc in q.docs) {
        final c = ServiceCategory.fromDoc(doc);
        if (c.active) map[c.id] = c;
      }
      return map;
    });
  }
}
