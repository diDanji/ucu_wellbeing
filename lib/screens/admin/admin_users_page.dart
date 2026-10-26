import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/user_admin_service.dart';
import '../home/home_page.dart';

/// FR9 – admin assigns roles (student / staff / admin) and, for staff,
/// the one service they work for.
class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key, required this.me});
  final AppUser me;

  @override
  Widget build(BuildContext context) {
    final admin = UserAdminService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin · User roles'),
        actions: const [SignOutButton()],
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: admin.allUsers(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final users = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = users[i];
              final isMe = u.uid == me.uid;
              return ListTile(
                leading: CircleAvatar(child: Text(u.fullName.isEmpty ? '?' : u.fullName[0].toUpperCase())),
                title: Text(u.fullName.isEmpty ? '(no name)' : u.fullName),
                subtitle: Text(u.role == UserRole.staff ? '${u.email}\nStaff · ${u.serviceName}' : u.email),
                isThreeLine: u.role == UserRole.staff,
                trailing: isMe
                    ? const Chip(label: Text('You · admin'))
                    : OutlinedButton(
                        onPressed: () => _editRole(context, admin, u),
                        child: Text(u.role.name),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editRole(BuildContext context, UserAdminService admin, AppUser u) async {
    var role = u.role;
    String? serviceId = u.serviceId;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Role for ${u.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(value: UserRole.student, label: Text('Student')),
                  ButtonSegment(value: UserRole.staff, label: Text('Staff')),
                  ButtonSegment(value: UserRole.admin, label: Text('Admin')),
                ],
                selected: {role},
                onSelectionChanged: (s) => setState(() => role = s.first),
              ),
              if (role == UserRole.staff) ...[
                const SizedBox(height: 16),
                Text('Service they work for', style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kServices.entries
                      .map((e) => ChoiceChip(
                            label: Text(e.value),
                            selected: serviceId == e.key,
                            onSelected: (_) => setState(() => serviceId = e.key),
                          ))
                      .toList(),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await admin.setRole(uid: u.uid, role: role, serviceId: serviceId);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setState(() => error = e is ArgumentError ? e.message.toString() : 'Could not save: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
