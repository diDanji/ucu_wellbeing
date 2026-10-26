import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../home/home_page.dart';

/// Staff landing page. The request inbox and service-info editor for
/// [AppUser.serviceId] are built in Sprint 3; this proves the role routing.
class StaffHome extends StatelessWidget {
  const StaffHome({super.key, required this.me});
  final AppUser me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff portal'),
        actions: const [SignOutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Welcome, ${me.fullName.split(' ').first}', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(me.email),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            Chip(label: Text('Role: ${me.role.name}')),
            Chip(avatar: const Icon(Icons.support_agent, size: 18), label: Text(me.serviceName)),
          ]),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox_outlined),
              title: Text('Requests · ${me.serviceName}'),
              subtitle: const Text('Coming in Sprint 3: only requests sent to your service appear here.'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.edit_note_outlined),
              title: Text('Service information'),
              subtitle: Text('Coming in Sprint 3: keep location, hours and contacts up to date.'),
            ),
          ),
        ],
      ),
    );
  }
}
