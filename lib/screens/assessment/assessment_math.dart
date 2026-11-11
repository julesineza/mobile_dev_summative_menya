
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';


class AssessmentMath extends StatelessWidget {
  const AssessmentMath({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFAF7F3);
    const green = Color(0xFF30764F);
    const textColor = Color(0xFF252525);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Color.fromRGBO(234, 245, 238, 1),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'BN',
                      style: TextStyle(
                        color: green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bruno N.: Quick Check',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3EB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Student 5 of 45',
                      style: TextStyle(
                        color: green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 27),

              // Passage label
              const Text(
                'English PASSAGE (LEVEL 2)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF73777C),
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 9),

              // Passage card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEAE3DC),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '" 12 / 3 = ? '
                      '"',
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Ask the student to solve using blocks or memory. Select response level below. '
                      'Track pause rate and errors.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF73777C),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Response level label
              const Text(
                'SELECT A RESPONSE LEVEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF73777C),
                ),
              ),

              const SizedBox(height: 12),

              // Response level options
              Row(
                children: [
                  Expanded(
                    child: _ResponseOption(
                      number: '1',
                      label: 'Struggling',
                      selected: true,
                      color: const Color(0xFFE3291F),
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _ResponseOption(
                      number: '2',
                      label: 'Developing',
                      selected: false,
                      color: green,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _ResponseOption(
                      number: '3',
                      label: 'Proficient',
                      selected: false,
                      color: green,
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Response descriptions
              const Text(
                '1  Struggling — needs frequent help\n'
                '2  Developing — reads with some support\n'
                '3  Proficient — reads independently',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Color(0xFF555F5A),
                ),
              ),

              const Spacer(),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Save & next student',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 11),

              // Skip button
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF73777C),
                    side: const BorderSide(
                      color: Color(0xFFEAE3DC),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    'Skip Assessment for Now',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),

              const SizedBox(height: 19),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable response option
class _ResponseOption extends StatelessWidget {
  final String number;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ResponseOption({
    required this.number,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFEFED)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color
                : const Color(0xFFEAE3DC),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF252525),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: selected
                    ? color
                    : const Color(0xFF252525),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
