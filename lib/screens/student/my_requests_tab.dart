import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/support_request.dart';
import '../../services/request_service.dart';
import 'request_detail_page.dart';
import 'request_ui.dart';
import 'service_ui.dart';

/// FR5 - the student's own requests and where each one has reached.
/// (The rules only ever return requests this student sent.)
class MyRequestsTab extends StatefulWidget {
  const MyRequestsTab({super.key});

  @override
  State<MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<MyRequestsTab> {
  late final Stream<List<SupportRequest>> _requests = RequestService().myRequests();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<SupportRequest>>(
      stream: _requests,
      builder: (context, snap) {
        final children = <Widget>[
          Text('My requests', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Only you and the service you contacted can see these.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
        ];
        if (snap.hasError) {
          children.add(_Empty('Could not load your requests: ${snap.error}'));
        } else if (!snap.hasData) {
          children.add(const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ));
        } else if (snap.data!.isEmpty) {
          children.add(const _Empty(
            'You have not sent any requests yet.\n'
            'Open a service in the Services tab and tap "Request support".',
          ));
        } else {
          final all = snap.data!;
          final open = all.where((r) => !r.isFinal).toList();
          final done = all.where((r) => r.isFinal).toList();
          if (open.isNotEmpty) {
            children.add(Text('Open', style: theme.textTheme.titleMedium));
            children.add(const SizedBox(height: 8));
            children.addAll(open.map((r) => _RequestCard(request: r)));
          }
          if (done.isNotEmpty) {
            children.add(const SizedBox(height: 8));
            children.add(Text('Finished', style: theme.textTheme.titleMedium));
            children.add(const SizedBox(height: 8));
            children.addAll(done.map((r) => _RequestCard(request: r)));
          }
        }
        children.add(const NotEmergencyNote());
        return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: children);
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final SupportRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = request;
    final needsReply = r.status == 'info_requested';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RequestDetailPage(requestId: r.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(serviceIcon(r.serviceId)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kServices[r.serviceId] ?? r.serviceId, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(kRequestTypes[r.requestType] ?? r.requestType),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      RequestStatusChip(r.status),
                      Text(
                        r.createdAt == null ? 'Sending…' : 'Sent ${formatDate(r.createdAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ]),
                    if (needsReply) ...[
                      const SizedBox(height: 8),
                      Text(
                        'The team asked you a question. Tap to reply.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
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

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(text, textAlign: TextAlign.center),
      );
}
