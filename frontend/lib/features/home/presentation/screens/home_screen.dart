import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/viewmodels/auth_view_model.dart';

/// Placeholder shown once a session is confirmed. Day 1 scope ends here —
/// the create-story form, My Stories list, and detail view arrive on
/// Day 2/3 per the project plan.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Story Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signed in as ${user?.name ?? ''}', style: Theme.of(context).textTheme.titleMedium),
            Text(user?.email ?? ''),
            const SizedBox(height: 24),
            const Text('My Stories, Create, and Search arrive in later days.'),
          ],
        ),
      ),
    );
  }
}
