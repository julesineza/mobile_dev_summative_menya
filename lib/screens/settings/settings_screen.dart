import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/school_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_snackbar.dart';
import 'edit_profile_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SchoolProvider>().load(); // to show the school's name
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final schools = context.watch<SchoolProvider>();
    final profile = auth.profile;
    final email = auth.firebaseUser?.email ?? '';

    final details = [
      email,
      if (profile != null && profile.schoolId.isNotEmpty)
        schools.nameFor(profile.schoolId),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Profile'),
          Card(
            child: ListTile(
              title: Text(
                (profile?.name.isNotEmpty ?? false) ? profile!.name : email,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(details),
              trailing: IconButton(
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined),
                onPressed: profile == null
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (_) => EditProfileDialog(profile: profile),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.class_outlined),
              title: const Text('My classes'),
              subtitle: const Text('Add, rename or remove classes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.classes),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Appearance'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Notifications'),
          Card(
            child: SwitchListTile(
              title: const Text('Assessment reminders'),
              subtitle: const Text('Remind me to run quick checks'),
              value: settings.notificationsEnabled,
              onChanged: settings.setNotificationsEnabled,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: auth.isLoading
                ? null
                : () async {
                    final ok = await auth.signOut();
                    if (!ok && context.mounted) {
                      showAppSnackBar(
                        context,
                        auth.errorMessage ?? 'Could not sign out.',
                        isError: true,
                      );
                    }
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: context.palette.border),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: context.palette.textSecondary,
      ),
    ),
  );
}
