import 'package:flutter/material.dart';

import '../../models/support_service.dart';
import '../../services/directory_service.dart';
import 'service_ui.dart';

/// FR3 - everything a student needs before reaching a service:
/// where it is, when it is open, who to contact, how to access it,
/// what to expect, whether an appointment is needed and how soon they hear back.
class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({super.key, required this.serviceId, this.initialName});
  final String serviceId;
  final String? initialName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SupportService?>(
      stream: DirectoryService().service(serviceId),
      builder: (context, snap) {
        final s = snap.data;
        return Scaffold(
          appBar: AppBar(title: Text(s?.name ?? initialName ?? 'Service')),
          body: () {
            if (snap.hasError || (snap.connectionState == ConnectionState.active && s == null)) {
              // A draft or removed service is refused by the security rules.
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text("This service isn't available right now.", textAlign: TextAlign.center),
                ),
              );
            }
            if (s == null) return const Center(child: CircularProgressIndicator());
            return _Details(service: s);
          }(),
        );
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.service});
  final SupportService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = service;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Icon(serviceIcon(s.id), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(s.name, style: theme.textTheme.headlineSmall)),
        ]),
        if (s.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(s.description, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 16),
        Card(
          child: Column(children: [
            _InfoRow(icon: Icons.place_outlined, label: 'Where to go', value: s.location),
            _InfoRow(icon: Icons.schedule, label: "When it's open", value: s.operatingHours),
            _InfoRow(icon: Icons.call_outlined, label: 'Who to contact', value: s.contactMethod),
            _InfoRow(icon: Icons.login, label: 'How to access it', value: s.accessMethod),
            _InfoRow(icon: Icons.groups_outlined, label: 'Who can use it', value: s.eligibility),
            _InfoRow(
              icon: Icons.event_available_outlined,
              label: 'Appointment',
              value: s.appointmentRequired ? 'An appointment is needed' : 'No appointment needed',
            ),
            _InfoRow(icon: Icons.timer_outlined, label: 'Expected response time', value: s.expectedResponseTime),
          ]),
        ),
        const SizedBox(height: 16),
        Text('What to expect', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _ValueText(s.whatToExpect),
        if (s.updatedAt != null) ...[
          const SizedBox(height: 16),
          Text('Information last updated ${formatDate(s.updatedAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: null, // Sprint 3: support requests (FR4)
          icon: const Icon(Icons.send_outlined),
          label: const Text('Request support (coming soon)'),
        ),
        const NotEmergencyNote(),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: _ValueText(value),
    );
  }
}

/// Shows a value, or an honest "not yet confirmed" note for placeholders.
class _ValueText extends StatelessWidget {
  const _ValueText(this.value);
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (SupportService.isMissing(value)) {
      return Text(
        'Not yet confirmed by the service',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.outline,
        ),
      );
    }
    return Text(value!.trim(), style: theme.textTheme.bodyMedium);
  }
}
