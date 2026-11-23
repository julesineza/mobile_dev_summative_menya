// owner: member 4. support plan screen.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_routes.dart';
import '../../core/constants/colors.dart';
import '../../core/support_options.dart';
import '../../models/remedial_club.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/app_snackbar.dart';
import 'review_widgets.dart';

/// pick an activity, add a note and optionally refer to a remedial club.
class SupportPlanScreen extends StatefulWidget {
  const SupportPlanScreen({super.key, required this.studentId, this.resultId});
  final String studentId;
  final String? resultId;

  @override
  State<SupportPlanScreen> createState() => _SupportPlanScreenState();
}

class _SupportPlanScreenState extends State<SupportPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<ReviewProvider>();
      // keep the draft when coming from the review screen for this learner.
      final sameFlow =
          p.student?.id == widget.studentId &&
          p.result != null &&
          (widget.resultId == null || p.result!.id == widget.resultId);
      if (!sameFlow) p.loadStudent(widget.studentId, resultId: widget.resultId);
    });
  }

  String get _teacherId => context.read<AuthProvider>().firebaseUser?.uid ?? '';

  /// "decide later" saves the plan without a recheck date.
  Future<void> _decideLater(ReviewProvider p) async {
    if (!p.canChooseRecheck) {
      context.go(AppRoutes.historyPath(widget.studentId));
      return;
    }
    final ok = await p.savePlan(teacherId: _teacherId);
    if (!mounted) return;
    if (ok) {
      context.push(AppRoutes.planSavedPath(widget.studentId));
    } else {
      showAppSnackBar(context, p.error ?? 'Could not save.', isError: true);
    }
  }

  Future<void> _newClub(ReviewProvider p) async {
    // the dialog owns its text controllers and disposes them only after its
    // closing animation ends. disposing them here, right after showDialog
    // returns, crashed with "_dependents.isEmpty".
    final club = await showDialog<({String name, String schedule})>(
      context: context,
      builder: (_) => const _NewClubDialog(),
    );
    if (club == null || !mounted) return;
    final clubName = club.name;
    final clubSchedule = club.schedule;
    final ok = await p.createClub(
      name: clubName,
      teacherId: _teacherId,
      schedule: clubSchedule,
    );
    if (!mounted) return;
    if (!ok) {
      showAppSnackBar(
        context,
        p.error ?? 'Could not create club.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReviewProvider>();
    final student = p.student;
    final ready = student != null && p.result != null;

    return FlowPage(
      title: 'Plan a little support',
      subtitle: 'Choose an activity based on what you observed.',
      stepLabel: '5 OF 6',
      body: ready
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LearnerHeader(student: student),
                const SizedBox(height: 16),
                const SectionLabel('Support activity'),
                for (final a in SupportActivity.values)
                  _ActivityCard(
                    activity: a,
                    selected: p.activity == a,
                    onTap: () => p.selectActivity(a),
                  ),
                const SizedBox(height: 12),
                const SectionLabel('Teacher note (optional)'),
                TextField(
                  onChanged: p.setPlanNote,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Focus or observation',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ClubPicker(provider: p, onNewClub: () => _newClub(p)),
              ],
            )
          : LoadGate(
              provider: p,
              needsResult: true,
              onRetry: () =>
                  p.loadStudent(widget.studentId, resultId: widget.resultId),
              builder: (_) => const SizedBox.shrink(),
            ),
      bottom: ready
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlowButton(
                  label: 'Choose a recheck date',
                  onPressed: p.canChooseRecheck
                      ? () => context.push(
                          AppRoutes.recheckPath(widget.studentId),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                FlowTextButton(
                  label: 'Decide later',
                  onPressed: p.isLoading ? null : () => _decideLater(p),
                ),
              ],
            )
          : null,
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.selected,
    required this.onTap,
  });
  final SupportActivity activity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      key: Key('activity_${activity.name}'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.white,
          border: Border.all(
            color: selected ? AppColors.button : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected ? AppColors.button : AppColors.divider,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ClubPicker extends StatelessWidget {
  const _ClubPicker({required this.provider, required this.onNewClub});
  final ReviewProvider provider;
  final VoidCallback onNewClub;

  @override
  Widget build(BuildContext context) {
    final clubs = provider.clubsForResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Refer to a remedial club (optional)'),
        DropdownButtonFormField<RemedialClub?>(
          key: const Key('club_dropdown'),
          initialValue: provider.selectedClub,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          hint: Text(
            clubs.isEmpty ? 'No clubs yet' : 'No club',
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          items: [
            const DropdownMenuItem<RemedialClub?>(
              value: null,
              child: Text('No club'),
            ),
            for (final c in clubs)
              DropdownMenuItem<RemedialClub?>(
                value: c,
                child: Text(
                  c.schedule == null ? c.name : '${c.name} · ${c.schedule}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: provider.selectClub,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onNewClub,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New club'),
          ),
        ),
      ],
    );
  }
}

/// asks for the new club's name and schedule; pops with them, or null on cancel.
class _NewClubDialog extends StatefulWidget {
  const _NewClubDialog();

  @override
  State<_NewClubDialog> createState() => _NewClubDialogState();
}

class _NewClubDialogState extends State<_NewClubDialog> {
  final _name = TextEditingController();
  final _schedule = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _schedule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New remedial club'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Club name'),
          ),
          TextField(
            controller: _schedule,
            decoration: const InputDecoration(
              labelText: 'Schedule (optional)',
              hintText: 'Tue/Thu 3pm',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            name: _name.text,
            schedule: _schedule.text,
          )),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
