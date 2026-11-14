import 'package:flutter/material.dart';

import '../../models/support_request.dart';
import '../../models/support_service.dart';
import '../../services/request_service.dart';
import 'reach_now_card.dart';
import 'request_sent_page.dart';
import 'service_ui.dart';

/// FR4 / NFR1 - a short, private form to ask one service for support.
/// Only what staff need to reach the student is collected (data minimisation).
class RequestSupportPage extends StatefulWidget {
  const RequestSupportPage({super.key, required this.service});
  final SupportService service;

  @override
  State<RequestSupportPage> createState() => _RequestSupportPageState();
}

class _RequestSupportPageState extends State<RequestSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _requests = RequestService();
  final _contact = TextEditingController();
  final _note = TextEditingController();

  String? _type;
  String _method = 'sms';
  String? _urgency;
  String _phoneDraft = '';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _isEmail => _method == 'email';

  void _changeMethod(String m) {
    setState(() {
      if (_isEmail && m != 'email') {
        _contact.text = _phoneDraft;
      } else if (!_isEmail && m == 'email') {
        _phoneDraft = _contact.text;
        _contact.text = _requests.myEmail ?? '';
      }
      _method = m;
    });
  }

  String? _validateContact(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return _isEmail ? 'Enter an email address' : 'Enter a phone number';
    if (t.length > kContactMaxLength) return 'That is too long';
    if (_isEmail) {
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
      return ok ? null : 'Enter a valid email address';
    }
    final digits = t.replaceAll(RegExp(r'\D'), '');
    final ok = RegExp(r'^\+?[0-9 ()-]+$').hasMatch(t) && digits.length >= 9 && digits.length <= 15;
    return ok ? null : 'Enter a valid phone number, e.g. 07XX XXX XXX';
  }

  Future<void> _send() async {
    setState(() => _error = null);
    if (_type == null) {
      setState(() => _error = 'Choose what you would like help with.');
      return;
    }
    if (_urgency == null) {
      setState(() => _error = 'Choose how soon you need this.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final id = await _requests.sendRequest(
        serviceId: widget.service.id,
        requestType: _type!,
        preferredContact: _method,
        contactValue: _contact.text,
        urgency: _urgency!,
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => RequestSentPage(
          requestId: id,
          service: widget.service,
          preferredContact: _method,
          urgency: _urgency!,
        ),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = 'Your request could not be sent. Please try again. ($e)');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.service;
    return Scaffold(
      appBar: AppBar(title: const Text('Request support')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(serviceIcon(s.id)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(s.name, style: theme.textTheme.titleLarge)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Only the ${s.name} team can see this request. '
              'They will contact you the way you choose below.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // A request is never the only door: show how to reach the service right now.
            ReachNowCard(service: s, urgent: _urgency == 'asap'),

            // ---- 1. what kind of help
            const SizedBox(height: 24),
            Text('1. What would you like help with?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in kRequestTypes.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _type == e.key,
                    onSelected: (_) => setState(() {
                      _type = e.key;
                      _error = null;
                    }),
                  ),
              ],
            ),

            // ---- 2. how soon (the student decides; the app does not judge)
            const SizedBox(height: 24),
            Text('2. How soon do you need this?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in kUrgencyLevels.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _urgency == e.key,
                    onSelected: (_) => setState(() {
                      _urgency = e.key;
                      _error = null;
                    }),
                  ),
              ],
            ),
            if (_urgency == 'asap') ...[
              const SizedBox(height: 8),
              Text(
                'Your request will be shown at the top of the team\'s list. '
                'If it cannot wait, use the contact details above.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],

            // ---- 3. how to be contacted
            const SizedBox(height: 24),
            Text('3. How should they contact you?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final e in kContactMethods.entries)
                  ButtonSegment(
                    value: e.key,
                    label: Text(e.value),
                    icon: Icon(switch (e.key) {
                      'call' => Icons.call_outlined,
                      'sms' => Icons.sms_outlined,
                      _ => Icons.email_outlined,
                    }),
                  ),
              ],
              selected: {_method},
              onSelectionChanged: (sel) => _changeMethod(sel.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              keyboardType: _isEmail ? TextInputType.emailAddress : TextInputType.phone,
              decoration: InputDecoration(
                labelText: _isEmail ? 'Email address' : 'Phone number',
                hintText: _isEmail ? 'name@example.com' : '07XX XXX XXX',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(_isEmail ? Icons.email_outlined : Icons.phone_outlined),
              ),
              validator: _validateContact,
            ),

            // ---- 4. optional note
            const SizedBox(height: 24),
            Text('4. Anything they should know? (optional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              minLines: 3,
              maxLines: 5,
              maxLength: kNoteMaxLength,
              decoration: const InputDecoration(
                hintText: 'For example, the best days or times to reach you.',
                border: OutlineInputBorder(),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined, size: 18, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please do not write medical details or a diagnosis here. '
                    'Keep it short; the team will talk with you about the details.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_outlined),
              label: const Text('Send request'),
            ),
            const NotEmergencyNote(),
          ],
        ),
      ),
    );
  }
}
