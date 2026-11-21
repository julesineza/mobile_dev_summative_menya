import 'package:flutter/material.dart';
import 'package:mobile_dev_summative_menya/app_routes.dart';
import 'package:mobile_dev_summative_menya/providers/assessment_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';

// ── Local UI-only model ───────────────────────────────────────────────────────
// Wraps [AssessmentLearner] with a selection toggle for the multi-select UI.
// schoolId and classId are carried from Firestore so the provider gets real IDs.

class _UILearner {
  final String id;
  final String name;
  final String initials;
  final String className;
  final String schoolId;
  final String classId;
  bool isSelected;

  _UILearner({
    required this.id,
    required this.name,
    required this.initials,
    required this.className,
    required this.schoolId,
    required this.classId,
    this.isSelected = false,
  });
}

// ── Page ─────────────────────────────────────────────────────────────────────

class SelectLearnersPage extends StatefulWidget {
  const SelectLearnersPage({super.key});

  @override
  State<SelectLearnersPage> createState() => _SelectLearnersPageState();
}

class _SelectLearnersPageState extends State<SelectLearnersPage> {
  // Start with an empty list — Firestore is the only source of truth.
  List<_UILearner> _learners = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLearners();
  }

  Future<void> _loadLearners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<AssessmentProvider>();
      // Try Firestore first.
      var loaded = await provider.loadLearners();

      // If Firestore returned nothing, use whatever the provider already has
      // (e.g. pre-loaded by tests or by a previous setLearners call).
      if (loaded.isEmpty && provider.learners.isNotEmpty) {
        loaded = provider.learners;
      }

      if (!mounted) return;
      setState(() {
        _learners = loaded
            .map(
              (l) => _UILearner(
                id: l.id,
                name: l.name,
                initials: l.initials,
                className: l.className,
                schoolId: l.schoolId,
                classId: l.classId,
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load learners. Check your connection.';
      });
    }
  }

  int get _selectedCount => _learners.where((e) => e.isSelected).length;
  bool get _allSelected => _learners.isNotEmpty && _selectedCount == _learners.length;

  void _toggleAll() {
    setState(() {
      final newValue = !_allSelected;
      for (final l in _learners) {
        l.isSelected = newValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const green = AppColors.button;
    const lightGreen = AppColors.primarySoft;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.chevron_left, color: green, size: 20),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '1 OF 6',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.secondaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorState(green)
                      : _learners.isEmpty
                          ? _buildEmptyState(green)
                          : _buildLearnerList(green, lightGreen),
            ),

            // ── Bottom button ──────────────────────────────────────────────
            if (!_isLoading && _errorMessage == null)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _selectedCount == 0
                        ? null
                        : () async {
                            final selected =
                                _learners.where((e) => e.isSelected).toList();

                            final provider = context.read<AssessmentProvider>();
                            provider.setLearners(
                              selected
                                  .map(
                                    (l) => AssessmentLearner(
                                      id: l.id,
                                      name: l.name,
                                      initials: l.initials,
                                      className: l.className,
                                      // Use real IDs from Firestore, not hardcoded fallbacks.
                                      schoolId: l.schoolId,
                                      classId: l.classId,
                                    ),
                                  )
                                  .toList(),
                            );
                            await provider.prepareAssessment();

                            if (!mounted) return;
                            final route =
                                provider.selectedChoice == UserChoice.reading
                                    ? AppRoutes.prepareReading
                                    : AppRoutes.assessMath;
                            Navigator.of(context).pushNamed(route);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      disabledBackgroundColor: green.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedCount == 0
                          ? 'Select learners to continue'
                          : 'Continue with $_selectedCount learner${_selectedCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── List body ─────────────────────────────────────────────────────────────

  Widget _buildLearnerList(Color green, Color lightGreen) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      children: [
        const Text(
          'Select learners',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a small group for this session.',
          style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 20),

        // Select-all row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_learners.length} LEARNERS IN CLASS',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: _toggleAll,
              child: Text(
                _allSelected ? 'Deselect all' : 'Select all',
                style: const TextStyle(
                  color: AppColors.button,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Learner cards
        ..._learners.map((learner) {
          final isSelected = learner.isSelected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => learner.isSelected = !learner.isSelected),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? lightGreen : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? green : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? green : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        learner.initials,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.secondaryText,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name + class
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            learner.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            learner.className,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Checkbox
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isSelected ? green : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isSelected ? green : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 60),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'You can skip an absent learner or pause between checks.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Empty / error states ──────────────────────────────────────────────────

  Widget _buildEmptyState(Color green) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            const Text(
              'No learners found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No students are registered for this class yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLearners,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Color green) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            const Text(
              'Connection issue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Could not load learners.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.secondaryText, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLearners,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: green),
            ),
          ],
        ),
      ),
    );
  }
}
