import 'package:flutter/material.dart';

import '../../models/support_service.dart';

/// Campus emergency contact. NOT yet confirmed with UCU, so it is a
/// placeholder and is not shown until a real value replaces it.
const String kCampusEmergencyContact = '[To be confirmed with UCU]';

/// "You don't have to wait": the service's own contact, place and hours,
/// so a request is never the only way to reach help.
class ReachNowCard extends StatelessWidget {
  const ReachNowCard({super.key, required this.service, this.urgent = false});
  final SupportService service;

  /// True when the student chose "As soon as possible".
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = service;
    final bg = urgent ? theme.colorScheme.errorContainer : theme.colorScheme.secondaryContainer;
    final fg = urgent ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSecondaryContainer;

    Widget line(IconData icon, String label, String? value) {
      final missing = SupportService.isMissing(value);
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                missing ? '$label: not yet confirmed by the service' : '$label: ${value!.trim()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontStyle: missing ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      color: bg,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              urgent ? "Don't wait for a reply" : 'Need to talk to someone today?',
              style: theme.textTheme.titleMedium?.copyWith(color: fg),
            ),
            const SizedBox(height: 4),
            Text(
              'You do not have to wait. You can reach ${s.name} directly:',
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
            line(Icons.call_outlined, 'Contact', s.contactMethod),
            line(Icons.place_outlined, 'Where', s.location),
            line(Icons.schedule, 'Open', s.operatingHours),
            if (urgent) ...[
              const SizedBox(height: 10),
              Text(
                'If you or someone else is in immediate danger, contact emergency services '
                'or campus security straight away.',
                style: theme.textTheme.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
              if (!SupportService.isMissing(kCampusEmergencyContact))
                line(Icons.emergency_outlined, 'Campus emergency', kCampusEmergencyContact),
            ],
          ],
        ),
      ),
    );
  }
}
