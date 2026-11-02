import 'package:cloud_firestore/cloud_firestore.dart';

/// A label used to group services and resources (EERD: CATEGORY),
/// stored at categories/{categoryId}.
/// (Named ServiceCategory because Flutter already has a class called Category.)
class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final String appliesTo; // service | resource | both
  final bool active;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.appliesTo,
    required this.active,
  });

  bool get forServices => appliesTo == 'service' || appliesTo == 'both';
  bool get forResources => appliesTo == 'resource' || appliesTo == 'both';

  factory ServiceCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ServiceCategory(
      id: doc.id,
      name: (d['name'] as String?) ?? doc.id,
      description: (d['description'] as String?) ?? '',
      appliesTo: (d['appliesTo'] as String?) ?? 'both',
      active: (d['status'] as String?) == 'active',
    );
  }
}
