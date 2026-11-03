import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/support_service.dart';
import '../../services/staff_content_service.dart';

/// FR6 / NFR5 - a staff member updates THEIR OWN service's information.
/// Plain labels and hints so no technical help is needed.
class EditServicePage extends StatefulWidget {
  const EditServicePage({super.key, required this.me, required this.serviceId});
  final AppUser me;
  final String serviceId;

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _content = StaffContentService();
  final _formKey = GlobalKey<FormState>();

  // field name in Firestore -> controller
  final Map<String, TextEditingController> _c = {
    for (final k in const [
      'name', 'description', 'location', 'operatingHours', 'contactMethod',
      'accessMethod', 'eligibility', 'whatToExpect', 'expectedResponseTime',
    ])
      k: TextEditingController(),
  };
  bool _appointmentRequired = false;
  bool _published = false;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  SupportService? _service;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _content.loadService(widget.serviceId);
      if (!mounted) return;
      if (s != null) {
        _c['name']!.text = s.name;
        _c['description']!.text = s.description;
        _c['location']!.text = s.location ?? '';
        _c['operatingHours']!.text = s.operatingHours ?? '';
        _c['contactMethod']!.text = s.contactMethod ?? '';
        _c['accessMethod']!.text = s.accessMethod ?? '';
        _c['eligibility']!.text = s.eligibility ?? '';
        _c['whatToExpect']!.text = s.whatToExpect ?? '';
        _c['expectedResponseTime']!.text = s.expectedResponseTime ?? '';
        _appointmentRequired = s.appointmentRequired;
        _published = s.status == 'published';
      }
      setState(() {
        _service = s;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load the service: $e'; _loading = false; });
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await _content.updateService(
        serviceId: widget.serviceId,
        editorUid: widget.me.uid,
        fields: {
          for (final e in _c.entries) e.key: e.value.text.trim(),
          'appointmentRequired': _appointmentRequired,
          'status': _published ? 'published' : 'draft',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_published ? 'Saved. Students can see the update.' : 'Saved as a draft. Students cannot see this service.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String key, String label, {String? hint, int lines = 1, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _c[key],
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 3,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: lines > 1,
        ),
        validator: (v) {
          final t = v?.trim() ?? '';
          if (required && t.isEmpty) return 'Please fill this in';
          if (key == 'name' && t.length > 80) return 'Keep the name under 80 characters';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.me.serviceName}')),
      body: () {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_service == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error ?? 'This service has not been set up yet. Ask an administrator to create it.',
                  textAlign: TextAlign.center),
            ),
          );
        }
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text('Students see these details in the app. Write them as you would explain them at the front desk.',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('Anything still in [square brackets] is shown to students as "Not yet confirmed".',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 16),
              _field('name', 'Service name', required: true),
              _field('description', 'Short description', hint: 'One or two sentences about what you offer', lines: 2),
              _field('location', 'Where to go', hint: 'e.g. building, floor and room'),
              _field('operatingHours', "When it's open", hint: 'e.g. days and times'),
              _field('contactMethod', 'Who to contact', hint: 'e.g. phone number or email'),
              _field('accessMethod', 'How to access it', hint: 'e.g. walk in, book ahead, send a request'),
              _field('eligibility', 'Who can use it', hint: 'e.g. all registered students'),
              _field('whatToExpect', 'What to expect', hint: 'What happens at a first visit', lines: 3),
              _field('expectedResponseTime', 'Expected response time', hint: 'e.g. within two working days'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('An appointment is needed'),
                value: _appointmentRequired,
                onChanged: (v) => setState(() => _appointmentRequired = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Published'),
                subtitle: Text(_published
                    ? 'Students can see this service in the directory.'
                    : 'Draft: students cannot see this service.'),
                value: _published,
                onChanged: (v) => setState(() => _published = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Save changes'),
              ),
            ],
          ),
        );
      }(),
    );
  }
}
