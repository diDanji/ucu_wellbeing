import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wellbeing_resource.dart';

/// FR2 - reads wellbeing resources for students.
/// As with services, the query must ask ONLY for published resources,
/// because the security rules refuse any query that could return drafts.
class ResourceService {
  ResourceService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  Stream<List<WellbeingResource>> publishedResources() {
    return _db
        .collection('resources')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((q) {
      final list = q.docs.map(WellbeingResource.fromDoc).toList();
      // Newest first; undated ones last, then by title.
      list.sort((a, b) {
        final ad = a.publishedAt, bd = b.publishedAt;
        if (ad != null && bd != null && ad != bd) return bd.compareTo(ad);
        if (ad == null && bd != null) return 1;
        if (ad != null && bd == null) return -1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return list;
    });
  }

  /// One resource. A draft is refused by the rules (arrives as a stream error).
  Stream<WellbeingResource?> resource(String id) {
    return _db.collection('resources').doc(id).snapshots().map(
          (doc) => doc.exists ? WellbeingResource.fromDoc(doc) : null,
        );
  }
}
