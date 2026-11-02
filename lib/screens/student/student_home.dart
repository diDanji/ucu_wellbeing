import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/service_category.dart';
import '../../models/support_service.dart';
import '../../services/directory_service.dart';
import '../home/home_page.dart';
import 'service_detail_page.dart';
import 'service_ui.dart';

/// FR3 - the student's home: a searchable directory of PUBLISHED services.
class StudentHome extends StatefulWidget {
  const StudentHome({super.key, required this.me});
  final AppUser me;

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final _directory = DirectoryService();
  late final Stream<List<SupportService>> _services = _directory.publishedServices();
  late final Stream<Map<String, ServiceCategory>> _categories = _directory.activeCategories();

  String _query = '';
  String? _categoryId; // null = all

  bool _matches(SupportService s) {
    if (_categoryId != null && s.categoryId != _categoryId) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return s.name.toLowerCase().contains(q) || s.description.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = widget.me.fullName.trim().split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UCU Wellbeing'),
        actions: const [SignOutButton()],
      ),
      body: StreamBuilder<Map<String, ServiceCategory>>(
        stream: _categories,
        builder: (context, catSnap) {
          final categories = catSnap.data ?? const <String, ServiceCategory>{};
          return StreamBuilder<List<SupportService>>(
            stream: _services,
            builder: (context, snap) {
              final children = <Widget>[
                Text('Hello, $firstName', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Find support services on campus', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search services',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ];

              if (snap.hasError) {
                children.add(_InfoText('Could not load services: ${snap.error}'));
              } else if (!snap.hasData) {
                children.add(const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ));
              } else {
                final all = snap.data!;
                // Only offer category chips that actually have published services.
                final usedIds = all.map((s) => s.categoryId).whereType<String>().toSet();
                final chips = categories.values.where((c) => c.forServices && usedIds.contains(c.id)).toList()
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
                children.add(Text('Support services', style: theme.textTheme.titleMedium));
                children.add(const SizedBox(height: 8));

                final shown = all.where(_matches).toList();
                if (all.isEmpty) {
                  children.add(const _InfoText('No services have been published yet.'));
                } else if (shown.isEmpty) {
                  children.add(const _InfoText('No services match your search.'));
                } else {
                  for (final s in shown) {
                    children.add(_ServiceCard(service: s, category: categories[s.categoryId]));
                  }
                }
              }

              children.add(const NotEmergencyNote());
              return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: children);
            },
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, this.category});
  final SupportService service;
  final ServiceCategory? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ServiceDetailPage(serviceId: service.id, initialName: service.name),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(serviceIcon(service.id)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: theme.textTheme.titleMedium),
                    if (service.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(service.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 4, children: [
                      if (category != null) _Tag(category!.name),
                      _Tag(service.appointmentRequired ? 'Appointment needed' : 'No appointment needed'),
                    ]),
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

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
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
