import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/view_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard_widgets.dart';

/// Home dashboard. One screen with the two Figma states:
///  - "01 Home" (empty): no quick checks yet
///  - "10 Resume a..." (populated): recent quick checks are listed
/// Data comes live from Firestore through the providers.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final classes = context.watch<ClassProvider>();
    final dashboard = context.watch<DashboardProvider>();

    final profileName = auth.profile?.name ?? '';
    final name = profileName.isNotEmpty
        ? profileName
        : (auth.firebaseUser?.displayName ?? 'Teacher');
    final selected = classes.selectedClass;

    return ListView(
      padding: AppSpacing.screenPadding.copyWith(top: 12, bottom: 24),
      children: [
        DashboardHeader(
          dateLabel: DateFormat('EEEE, MMMM d').format(DateTime.now()),
          name: name,
          onSettings: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(height: 16),
        if (classes.state == ViewState.loading)
          const InlineLoading()
        else if (classes.state == ViewState.error)
          InlineError(
            message: classes.errorMessage ?? 'Could not load classes.',
          )
        else if (selected == null)
          EmptyCard(
            icon: Icons.class_outlined,
            title: 'No classes yet',
            message: 'Create your first class to start tracking learners.',
            actionLabel: 'Create a class',
            onAction: () => context.push(AppRoutes.classes),
          )
        else ...[
          if (dashboard.summaryState == ViewState.error)
            const InlineError(message: 'Could not load your class overview.')
          else ...[
            OverviewCard(
              total: dashboard.summary.total,
              watch: dashboard.summary.watch,
              classes: classes.classes,
              selected: selected,
              onSelect: classes.select,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'ON TRACK',
                    value: dashboard.summary.onTrack,
                    caption: 'Reading & Math',
                    color: AppColors.button,
                    background: AppColors.primarySoft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'NEEDS SUPPORT',
                    value: dashboard.summary.needsSupport,
                    caption: 'Active support',
                    color: AppColors.warningStroke,
                    background: AppColors.warningFill,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          QuickCheckCta(onTap: () => context.go(AppRoutes.assess)),
          const SizedBox(height: 20),
          const Text(
            'Recent Quick Checks',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (dashboard.recentState == ViewState.loading)
            const InlineLoading()
          else if (dashboard.recentState == ViewState.error)
            const InlineError(message: 'Could not load recent checks.')
          else if (dashboard.recentChecks.isEmpty)
            const EmptyCard(
              icon: Icons.assignment_outlined,
              title: 'No quick checks yet',
              message: 'Start your first check to see it here.',
            )
          else
            for (final session in dashboard.recentChecks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RecentCheckTile(session: session),
              ),
        ],
      ],
    );
  }
}
