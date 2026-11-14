import 'package:flutter/material.dart';

import '../../models/support_request.dart';
import '../../models/support_service.dart';
import 'reach_now_card.dart';
import 'service_ui.dart';

/// FR4 - confirmation after a request is sent: a reference number and
/// what happens next, so the student is not left wondering.
class RequestSentPage extends StatelessWidget {
  const RequestSentPage({
    super.key,
    required this.requestId,
    required this.service,
    required this.preferredContact,
    required this.urgency,
  });
  final String requestId;
  final SupportService service;
  final String preferredContact;
  final String urgency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = requestId.length >= 6 ? requestId.substring(0, 6).toUpperCase() : requestId.toUpperCase();
    final how = (kContactMethods[preferredContact] ?? preferredContact).toLowerCase();
    final response = SupportService.isMissing(service.expectedResponseTime)
        ? null
        : service.expectedResponseTime!.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Request sent'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Your request has been sent', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('to ${service.name}', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text('Reference'),
                subtitle: Text(reference, style: theme.textTheme.titleMedium),
              ),
              const ListTile(
                leading: Icon(Icons.flag_outlined),
                title: Text('Status'),
                subtitle: Text('Submitted'),
              ),
              ListTile(
                leading: const Icon(Icons.hourglass_empty),
                title: const Text('How soon'),
                subtitle: Text(kUrgencyLevels[urgency] ?? urgency),
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('When to expect a reply'),
                subtitle: Text(response ?? 'The service has not confirmed a response time yet.'),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Text('What happens next', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'The ${service.name} team will review your request and contact you by $how. '
            'You can follow its progress in the "My requests" tab.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ReachNowCard(service: service, urgent: urgency == 'asap'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
          const NotEmergencyNote(),
        ],
      ),
    );
  }
}
