import 'package:flutter/material.dart';

import '../../models/service_category.dart';
import '../../models/wellbeing_resource.dart';
import '../../services/directory_service.dart';
import '../../services/resource_service.dart';
import 'resource_detail_page.dart';
import 'service_ui.dart';

/// FR2 - students browse PUBLISHED wellbeing information by category.
class ResourcesTab extends StatefulWidget {
  const ResourcesTab({super.key});

  @override
  State<ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> {
  late final Stream<List<WellbeingResource>> _resources = ResourceService().publishedResources();
  late final Stream<Map<String, ServiceCategory>> _categories = DirectoryService().activeCategories();

  String _query = '';
  String? _categoryId;

  bool _matches(WellbeingResource r) {
    if (_categoryId != null && r.categoryId != _categoryId) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return r.title.toLowerCase().contains(q) ||
        r.summary.toLowerCase().contains(q) ||
        r.content.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Map<String, ServiceCategory>>(
      stream: _categories,
      builder: (context, catSnap) {
        final categories = catSnap.data ?? const <String, ServiceCategory>{};
        return StreamBuilder<List<WellbeingResource>>(
          stream: _resources,
          builder: (context, snap) {
            final children = <Widget>[
              Text('Wellbeing information', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Short guides on looking after yourself at university', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search information',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ];

            if (snap.hasError) {
              children.add(_InfoText('Could not load information: ${snap.error}'));
            } else if (!snap.hasData) {
              children.add(const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ));
            } else {
              final all = snap.data!;
              final usedIds = all.map((r) => r.categoryId).whereType<String>().toSet();
              final chips = categories.values.where((c) => c.forResources && usedIds.contains(c.id)).toList()
                ..sort((a, b) => a.name.compareTo(b.name));
              if (chips.isNotEmpty) {
                children.add(const SizedBox(height: 12));
                children.add(SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _categoryId == null,
                        onSelected: (_) => setState(() => _categoryId = null),
                      ),
                    ),
                    for (final c in chips)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) => setState(() => _categoryId = c.id),
                        ),
                      ),
                  ]),
                ));
              }
              children.add(const SizedBox(height: 16));

              final shown = all.where(_matches).toList();
              if (all.isEmpty) {
                children.add(const _InfoText('No information has been published yet.'));
              } else if (shown.isEmpty) {
                children.add(const _InfoText('Nothing matches your search.'));
              } else {
                for (final r in shown) {
                  children.add(_ResourceCard(resource: r, category: categories[r.categoryId]));
                }
              }
            }

            children.add(const NotEmergencyNote());
            return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: children);
          },
        );
      },
    );
  }
}

IconData resourceIcon(String type) {
  switch (type) {
    case 'guide':
      return Icons.menu_book_outlined;
    case 'video':
      return Icons.play_circle_outline;
    default:
      return Icons.article_outlined;
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, this.category});
  final WellbeingResource resource;
  final ServiceCategory? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = resource.content.length > 140 ? '${resource.content.substring(0, 140).trim()}…' : resource.content;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ResourceDetailPage(resourceId: resource.id, initialTitle: resource.title),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
                child: Icon(resourceIcon(resource.resourceType)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.title, style: theme.textTheme.titleMedium),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    if (category != null) ...[
                      const SizedBox(height: 8),
                      Text(category!.name,
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(text, textAlign: TextAlign.center),
      );
}
