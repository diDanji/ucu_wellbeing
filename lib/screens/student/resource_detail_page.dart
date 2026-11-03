import 'package:flutter/material.dart';

import '../../models/wellbeing_resource.dart';
import '../../services/resource_service.dart';
import 'resources_tab.dart';
import 'service_ui.dart';

/// FR2 - reading one wellbeing resource.
class ResourceDetailPage extends StatelessWidget {
  const ResourceDetailPage({super.key, required this.resourceId, this.initialTitle});
  final String resourceId;
  final String? initialTitle;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WellbeingResource?>(
      stream: ResourceService().resource(resourceId),
      builder: (context, snap) {
        final r = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(r?.title ?? initialTitle ?? 'Information')),
          body: () {
            if (snap.hasError || (snap.connectionState == ConnectionState.active && r == null)) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text("This information isn't available right now.", textAlign: TextAlign.center),
                ),
              );
            }
            if (r == null) return const Center(child: CircularProgressIndicator());
            return _Body(resource: r);
          }(),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.resource});
  final WellbeingResource resource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = resource;
    final date = r.publishedAt ?? r.updatedAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(children: [
          Icon(resourceIcon(r.resourceType), color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(r.resourceType.isEmpty ? 'Article' : r.resourceType[0].toUpperCase() + r.resourceType.substring(1),
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
          if (date != null) ...[
            const Spacer(),
            Text(formatDate(date), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ],
        ]),
        const SizedBox(height: 12),
        Text(r.title, style: theme.textTheme.headlineSmall),
        if (r.summary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(r.summary, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 16),
        SelectableText(r.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
        const SizedBox(height: 24),
        Card(
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.support_agent, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Want to talk to someone? Go back and open the Services tab to see where to go and how to reach them.',
                  style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                ),
              ),
            ]),
          ),
        ),
        const NotEmergencyNote(),
      ],
    );
  }
}
