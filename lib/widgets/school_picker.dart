import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/view_state.dart';
import '../providers/school_provider.dart';
import 'app_text_field.dart';

/// Dropdown of schools loaded from Firestore. The chosen school id is written
/// to [selected]. Used on Register, Select school and Edit profile.
class SchoolPicker extends StatelessWidget {
  const SchoolPicker({super.key, required this.selected});

  final ValueNotifier<String?> selected;

  @override
  Widget build(BuildContext context) {
    final schools = context.watch<SchoolProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('School'),
        const SizedBox(height: 6),
        if (schools.state == ViewState.loading)
          const LinearProgressIndicator()
        else if (schools.state == ViewState.error)
          Row(
            children: [
              const Expanded(child: Text('Could not load schools.')),
              TextButton(
                onPressed: () => schools.load(force: true),
                child: const Text('Retry'),
              ),
            ],
          )
        else if (schools.schools.isEmpty)
          const Text(
            'No schools are set up yet. Ask your team leader to add schools in Firestore.',
          )
        else
          FormField<String>(
            initialValue: selected.value,
            validator: (_) =>
                selected.value == null ? 'Choose your school' : null,
            builder: (field) => DropdownMenu<String>(
              expandedInsets: EdgeInsets.zero,
              initialSelection: selected.value,
              hintText: 'Select your school',
              errorText: field.errorText,
              dropdownMenuEntries: [
                for (final school in schools.schools)
                  DropdownMenuEntry(value: school.id, label: school.name),
              ],
              onSelected: (value) {
                selected.value = value;
                field.didChange(value);
              },
            ),
          ),
      ],
    );
  }
}
