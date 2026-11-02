import 'package:flutter/material.dart';

/// Small shared pieces for the student service screens.

IconData serviceIcon(String serviceId) {
  switch (serviceId) {
    case 'counselling':
      return Icons.chat_bubble_outline;
    case 'peer_counselling':
      return Icons.people_outline;
    case 'chaplaincy':
      return Icons.volunteer_activism_outlined;
    case 'workshops':
      return Icons.event_outlined;
    default:
      return Icons.support_agent;
  }
}

String formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Shown on every student screen: the app helps people find support,
/// it is not an emergency or crisis service.
class NotEmergencyNote extends StatelessWidget {
  const NotEmergencyNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This app helps you find support. It is not an emergency service. '
              'If you or someone else is in immediate danger, contact emergency services '
              'or campus security straight away.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
