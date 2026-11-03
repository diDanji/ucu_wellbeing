import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../home/home_page.dart';
import 'edit_service_page.dart';
import 'staff_resources_page.dart';

/// Staff landing page (FR6). Staff keep THEIR OWN service's information
/// accurate and write wellbeing guides. The request inbox comes in Sprint 3.
class StaffHome extends StatelessWidget {
  const StaffHome({super.key, required this.me});
  final AppUser me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasService = me.serviceId != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff portal'),
        actions: const [SignOutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome, ${me.fullName.trim().split(' ').first}', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            Chip(label: Text('Role: ${me.role.name}')),
            Chip(avatar: const Icon(Icons.support_agent, size: 18), label: Text(me.serviceName)),
          ]),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_note_outlined),
              title: Text('Service information · ${me.serviceName}'),
              subtitle: const Text('Keep location, hours, contacts and what to expect up to date.'),
              trailing: const Icon(Icons.chevron_right),
              enabled: hasService,
              onTap: hasService
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => EditServicePage(me: me, serviceId: me.serviceId!),
                      ))
                  : null,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Wellbeing information'),
              subtitle: const Text('Write guides for students, save drafts and publish them.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StaffResourcesPage(me: me),
              )),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text('Requests · ${me.serviceName}'),
              subtitle: const Text('Coming in Sprint 3: only requests sent to your service appear here.'),
              enabled: false,
            ),
          ),
          if (!hasService) ...[
            const SizedBox(height: 16),
            Text('You are not assigned to a service yet. Ask an administrator to assign you.',
                style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
