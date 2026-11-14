import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/request_update.dart';
import '../../models/support_request.dart';
import '../../models/support_service.dart';
import '../../services/directory_service.dart';
import '../../services/request_service.dart';
import 'reach_now_card.dart';
import 'request_ui.dart';
import 'service_ui.dart';

/// FR5 - where one request has reached: a simple tracker
/// (Submitted -> Under review -> Contacted -> Closed), its history,
/// a reply box when staff ask a question, and a way to withdraw it.
class RequestDetailPage extends StatefulWidget {
  const RequestDetailPage({super.key, required this.requestId});
  final String requestId;

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  final _requests = RequestService();
  late final Stream<SupportRequest?> _request = _requests.request(widget.requestId);
  late final Stream<List<RequestUpdate>> _updates = _requests.updates(widget.requestId);
  Stream<SupportService?>? _service;

  final _reply = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() { _busy = true; _error = null; });
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (mounted) setState(() => _error = 'That did not work. Please try again. ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _reply.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Write your reply first.');
      return;
    }
    await _run(() => _requests.replyToStaff(widget.requestId, text), 'Reply sent. The team will review it.');
    if (mounted && _error == null) _reply.clear();
  }

  Future<void> _withdraw() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw this request?'),
        content: const Text('The team will see that you no longer need it. '
            'You can always send a new request later.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Withdraw')),
        ],
      ),
    );
    if (sure != true) return;
    await _run(() => _requests.withdraw(widget.requestId), 'Request withdrawn.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request')),
      body: StreamBuilder<SupportRequest?>(
        stream: _request,
        builder: (context, snap) {
          if (snap.hasError) {
            return const _Centered("This request can't be opened.");
          }
          if (!snap.hasData) {
            if (snap.connectionState == ConnectionState.active) {
              return const _Centered('This request was not found.');
            }
            return const Center(child: CircularProgressIndicator());
          }
          final r = snap.data!;
          _service ??= DirectoryService().service(r.serviceId);
          return _body(context, r);
        },
      ),
    );
  }

  Widget _body(BuildContext context, SupportRequest r) {
    final theme = Theme.of(context);
    final serviceName = kServices[r.serviceId] ?? r.serviceId;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Icon(serviceIcon(r.serviceId)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(serviceName, style: theme.textTheme.titleLarge),
              Text('Reference ${r.reference}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ]),
          ),
          RequestStatusChip(r.status),
        ]),
        const SizedBox(height: 16),

        // ---- tracker
        if (r.status == 'withdrawn')
          const _Banner(icon: Icons.undo, text: 'You withdrew this request.')
        else
          _Tracker(status: r.status),

        // ---- staff asked a question
        if (r.status == 'info_requested') ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.errorContainer,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('The team needs a little more information',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onErrorContainer)),
                const SizedBox(height: 4),
                Text('Their question is in the history below. Reply here:',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer)),
                const SizedBox(height: 12),
                TextField(
                  controller: _reply,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: kNoteMaxLength,
                  decoration: InputDecoration(
                    hintText: 'Your reply (no medical details, please)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _sendReply,
                    icon: const Icon(Icons.reply),
                    label: const Text('Send reply'),
                  ),
                ),
              ]),
            ),
          ),
        ],

        // ---- what was sent
        const SizedBox(height: 16),
        Text('What you sent', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(children: [
            _Line(Icons.help_outline, 'Help with', kRequestTypes[r.requestType] ?? r.requestType),
            _Line(Icons.hourglass_empty, 'How soon', kUrgencyLevels[r.urgency] ?? r.urgency),
            _Line(Icons.contact_phone_outlined, 'Contact me by',
                '${kContactMethods[r.preferredContact] ?? r.preferredContact}: ${r.contactValue}'),
            if ((r.note ?? '').isNotEmpty) _Line(Icons.notes, 'Note', r.note!),
            if (r.createdAt != null) _Line(Icons.event_outlined, 'Sent', formatDateTime(r.createdAt!)),
          ]),
        ),

        // ---- history
        const SizedBox(height: 16),
        Text('History', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<RequestUpdate>>(
          stream: _updates,
          builder: (context, snap) {
            if (snap.hasError) return Text('Could not load the history: ${snap.error}');
            if (!snap.hasData) return const LinearProgressIndicator();
            return Column(children: [for (final u in snap.data!) _HistoryRow(update: u, serviceName: serviceName)]);
          },
        ),

        // ---- still waiting? reach the service directly
        if (!r.isFinal) ...[
          const SizedBox(height: 16),
          StreamBuilder<SupportService?>(
            stream: _service,
            builder: (context, snap) {
              final s = snap.data;
              if (s == null) return const SizedBox.shrink();
              return ReachNowCard(service: s, urgent: r.isUrgent && r.status == 'submitted');
            },
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
        if (!r.isFinal) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _withdraw,
            icon: const Icon(Icons.undo),
            label: const Text('I no longer need this (withdraw)'),
          ),
        ],
        const NotEmergencyNote(),
      ],
    );
  }
}

/// Submitted -> Under review -> Contacted -> Closed.
class _Tracker extends StatelessWidget {
  const _Tracker({required this.status});
  final String status;

  static const _steps = ['submitted', 'under_review', 'contacted', 'closed'];
  static const _hints = {
    'submitted': 'Your request has reached the service.',
    'under_review': 'A member of the team is looking at it.',
    'contacted': 'The team has contacted you, or tried to.',
    'closed': 'This request is finished.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // "More information needed" sits at the "Under review" step.
    final current = _steps.indexOf(status == 'info_requested' ? 'under_review' : status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < _steps.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(children: [
                    Icon(
                      i < current
                          ? Icons.check_circle
                          : (i == current ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                      color: i <= current ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    ),
                    if (i < _steps.length - 1)
                      Container(
                        width: 2,
                        height: 28,
                        color: i < current ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      ),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          kRequestStatuses[_steps[i]]!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: i == current ? FontWeight.bold : FontWeight.normal,
                            color: i <= current ? null : theme.colorScheme.outline,
                          ),
                        ),
                        if (i == current)
                          Text(
                            status == 'info_requested'
                                ? 'The team asked you a question. Please reply below.'
                                : _hints[_steps[i]]!,
                            style: theme.textTheme.bodySmall,
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.update, required this.serviceName});
  final RequestUpdate update;
  final String serviceName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = update;
    final who = u.fromStaff ? '$serviceName team' : 'You';
    final what = switch (u.newStatus) {
      null => 'sent a message',
      'submitted' => 'sent the request',
      'withdrawn' => 'withdrew the request',
      'info_requested' => 'asked for more information',
      'under_review' => u.fromStaff ? 'started reviewing it' : 'replied',
      'contacted' => 'marked it as contacted',
      'closed' => 'closed the request',
      _ => 'updated the request',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(u.fromStaff ? Icons.support_agent : Icons.person_outline),
      title: Text('$who $what'),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if ((u.message ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Text('"${u.message}"', style: theme.textTheme.bodyMedium),
          ),
        Text(
          u.createdAt == null ? 'Just now' : formatDateTime(u.createdAt!),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ]),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) =>
      ListTile(dense: true, leading: Icon(icon), title: Text(label), subtitle: Text(value));
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(leading: Icon(icon), title: Text(text)),
      );
}

class _Centered extends StatelessWidget {
  const _Centered(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(text, textAlign: TextAlign.center)),
      );
}
