import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../admin/admin_users_page.dart';
import '../staff/staff_home.dart';
import '../student/student_home.dart';

/// Loads the signed-in user's profile and sends them to the right area
/// for their role (FR9). The role is read from Firestore, never chosen in the app.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<AppUser?>(
      stream: auth.profileStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return _Message('Could not load your profile: ${snap.error}', auth);
        }
        final profile = snap.data;
        if (profile == null) return _Message('Setting up your profile…', auth);

        switch (profile.role) {
          case UserRole.admin:
            return AdminUsersPage(me: profile);
          case UserRole.staff:
            return StaffHome(me: profile);
          case UserRole.student:
            return StudentHome(me: profile);
        }
      },
    );
  }
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Sign out',
        icon: const Icon(Icons.logout),
        onPressed: () => AuthService().signOut(),
      );
}

class _Message extends StatelessWidget {
  const _Message(this.text, this.auth);
  final String text;
  final AuthService auth;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('UCU Wellbeing'), actions: const [SignOutButton()]),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(text))),
      );
}
