import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/service_category.dart';
import '../../models/wellbeing_resource.dart';
import '../../services/directory_service.dart';
import '../../services/staff_content_service.dart';

/// FR6 / NFR5 - write or edit a wellbeing guide. Save as a draft,
/// publish it for students, or archive it (nothing is ever deleted).
/// (Approval by a second person before publishing, FR7, comes in Sprint 4.)
class EditResourcePage extends StatefulWidget {
  const EditResourcePage({super.key, required this.me, this.existing});
  final AppUser me;
  final WellbeingResource? existing;

  @override
  State<EditResourcePage> createState() => _EditResourcePageState();
}

class _EditResourcePageState extends State<EditResourcePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _body = TextEditingController();
  late final Stream<Map<String, ServiceCategory>> _categories = DirectoryService().activeCategories();

  String _type = 'article';
  String? _categoryId;
  String _status = 'draft';
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r != null) {
      _title.text = r.title;
      _summary.text = r.summary;
      _body.text = r.content;
      _type = (r.resourceType == 'guide') ? 'guide' : 'article';
      _categoryId = r.categoryId;
      _status = r.status;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = 'Choose a category so students can find this guide.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final content = StaffContentService();
    try {
      if (_isNew) {
        await content.createResource(
          authorUid: widget.me.uid,
          title: _title.text.trim(),
          summary: _summary.text.trim(),
          content: _body.text.trim(),
          resourceType: _type,
          categoryId: _categoryId!,
          status: _status,
        );
      } else {
        await content.updateResource(
          original: widget.existing!,
          title: _title.text.trim(),
          summary: _summary.text.trim(),
          content: _body.text.trim(),
          resourceType: _type,
          categoryId: _categoryId!,
          status: _status,
        );
      }
      if (!mounted) return;
      final msg = switch (_status) {
        'published' => 'Published. Students can read it now.',
        'archived' => 'Archived. Students can no longer see it.',
        _ => 'Saved as a draft. Students cannot see it yet.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New guide' : 'Edit guide')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Give the guide a title';
                if (t.length > 120) return 'Keep the title under 120 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _summary,
              decoration: const InputDecoration(
                labelText: 'Summary (optional)',
                hintText: 'One line students see first',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _body,
              minLines: 6,
              maxLines: 16,
              decoration: const InputDecoration(
                labelText: 'Text',
                hintText: 'Write in plain, friendly language. Point students to a service if they need more help.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Write the guide text';
                if (t.length > 20000) return 'The text is too long (over 20,000 characters)';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Type', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'article', label: Text('Article')),
                ButtonSegment(value: 'guide', label: Text('Step-by-step guide')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            StreamBuilder<Map<String, ServiceCategory>>(
              stream: _categories,
              builder: (context, snap) {
                final cats = (snap.data?.values ?? const <ServiceCategory>[])
                    .where((c) => c.forResources)
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
                if (!snap.hasData) return const LinearProgressIndicator();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in cats)
                      ChoiceChip(
                        label: Text(c.name),
                        selected: _categoryId == c.id,
                        onSelected: (_) => setState(() => _categoryId = c.id),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text('Who can see it', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                const ButtonSegment(value: 'draft', label: Text('Draft')),
                const ButtonSegment(value: 'published', label: Text('Published')),
                if (!_isNew) const ButtonSegment(value: 'archived', label: Text('Archived')),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              switch (_status) {
                'published' => 'Students will see this guide in the Information tab.',
                'archived' => 'Hidden from students, but kept for the record.',
                _ => 'Only staff can see drafts.',
              },
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_isNew ? 'Save guide' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
