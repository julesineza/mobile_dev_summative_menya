import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/assessment_colors.dart';
import '../../core/view_state.dart';
import '../../models/enums.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../widgets/student_widgets.dart';

class StudentRosterScreen extends StatelessWidget {
  const StudentRosterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StudentProvider>();
    final c = context.assessmentColors;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c.border),
    );

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Student Roster',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: p.setQuery,
                style: TextStyle(color: c.text),
                decoration: InputDecoration(
                  hintText: 'Search student name...',
                  hintStyle: TextStyle(color: c.hint),
                  prefixIcon: Icon(Icons.search, color: c.secondaryText),
                  filled: true,
                  fillColor: c.surface,
                  isDense: true,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterPill(
                      label: 'All (${p.total})',
                      selected: p.filter == RosterFilter.all,
                      onTap: () => p.setFilter(RosterFilter.all),
                    ),
                    const SizedBox(width: 8),
                    FilterPill(
                      label:
                          'Needs Support (${p.countOf(SupportStatus.needsSupport)})',
                      selected: p.filter == RosterFilter.needsSupport,
                      onTap: () => p.setFilter(RosterFilter.needsSupport),
                    ),
                    const SizedBox(width: 8),
                    FilterPill(
                      label: 'Watch (${p.countOf(SupportStatus.watch)})',
                      selected: p.filter == RosterFilter.watch,
                      onTap: () => p.setFilter(RosterFilter.watch),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SyncErrorBanner(
                message: p.syncError,
                onDismiss: p.clearSyncError,
              ),
              Expanded(child: _list(context, p)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, StudentProvider p) {
    final c = context.assessmentColors;
    if (p.state == ViewState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.state == ViewState.error) {
      return Center(
        child: Text(
          p.error ?? 'Could not load students.',
          style: TextStyle(color: c.text),
        ),
      );
    }
    final List<Student> students = p.visible;
    if (students.isEmpty) {
      return Center(
        child: Text(
          p.state == ViewState.idle
              ? 'No class selected.'
              : 'No students match.',
          style: TextStyle(color: c.secondaryText),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = students[i];
        return StudentRow(
          student: s,
          subtitle:
              'Class ${p.className} • ${lastAssessedLabel(s.lastAssessedAt)}',
          onTap: () => context.push('/students/${s.id}'),
        );
      },
    );
  }
}
