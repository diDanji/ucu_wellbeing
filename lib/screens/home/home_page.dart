import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';

/// Temporary home screen for Sprint 1: proves login works and shows the role.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('UCU Wellbeing'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: auth.profileStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load profile: ${snap.error}'));
          }
          final profile = snap.data;
          if (profile == null) {
            return const Center(child: Text('Setting up your profile…'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Hello, ${profile.fullName.split(' ').first}',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(profile.email),
              const SizedBox(height: 16),
              Chip(label: Text('Role: ${profile.role.name}')),
              const SizedBox(height: 24),
              const Text('Support services will appear here in Sprint 2.'),
            ],
          );
        },
      ),
    );
  }
}