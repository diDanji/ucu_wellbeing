import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/wellbeing_resource.dart';
import '../../services/staff_content_service.dart';
import 'edit_resource_page.dart';

/// FR6 - staff see all wellbeing guides (including drafts), edit their own
/// and write new ones.
class StaffResourcesPage extends StatefulWidget {
  const StaffResourcesPage({super.key, required this.me});
  final AppUser me;

  @override
  State<StaffResourcesPage> createState() => _StaffResourcesPageState();
}

class _StaffResourcesPageState extends State<StaffResourcesPage> {
  late final Stream<List<WellbeingResource>> _stream = StaffContentService().allResources();
  bool _mineOnly = true;

  void _open({WellbeingResource? existing}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditResourcePage(me: widget.me, existing: existing),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellbeing information')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.add),
        label: const Text('New guide'),
      ),
      body: StreamBuilder<List<WellbeingResource>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Could not load guides: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          final shown = _mineOnly ? all.where((r) => r.createdBy == widget.me.uid).toList() : all;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('My guides')),
                  ButtonSegment(value: false, label: Text('All guides')),
                ],
                selected: {_mineOnly},
                onSelectionChanged: (s) => setState(() => _mineOnly = s.first),
              ),
              const SizedBox(height: 16),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _mineOnly ? 'You have not written any guides yet. Tap "New guide" to start.' : 'No guides yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final r in shown)
                Card(
                  child: ListTile(
                    title: Text(r.title),
                    subtitle: Text(r.createdBy == widget.me.uid ? 'Written by you' : 'Written by someone else'),
                    leading: _StatusChip(r.status),
                    trailing: r.createdBy == widget.me.uid ? const Icon(Icons.edit_outlined) : null,
                    // Staff may only edit what they wrote (enforced by the rules too).
                    onTap: r.createdBy == widget.me.uid ? () => _open(existing: r) : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bg, fg) = switch (status) {
      'published' => ('Live', theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer),
      'archived' => ('Archived', theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant),
      _ => ('Draft', theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer),
    };
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}
