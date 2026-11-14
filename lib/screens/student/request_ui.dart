import 'package:flutter/material.dart';

import '../../models/support_request.dart';

/// Small shared pieces for request screens (student and, later, staff).

String formatDateTime(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m';
}

/// A coloured label for a request status.
class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      'info_requested' => (c.errorContainer, c.onErrorContainer),
      'contacted' => (c.primaryContainer, c.onPrimaryContainer),
      'closed' || 'withdrawn' => (c.surfaceContainerHighest, c.onSurfaceVariant),
      'under_review' => (c.tertiaryContainer, c.onTertiaryContainer),
      _ => (c.secondaryContainer, c.onSecondaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        kRequestStatuses[status] ?? status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
