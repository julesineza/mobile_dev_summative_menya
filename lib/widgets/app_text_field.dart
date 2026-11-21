import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: context.palette.textSecondary,
    ),
  );
}

/// Labelled text field. The show/hide-password toggle uses a ValueNotifier,
/// so no setState is needed.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final ValueNotifier<bool> _hidden = ValueNotifier(widget.obscure);

  @override
  void dispose() {
    _hidden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _hidden,
      builder: (context, hidden, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FieldLabel(widget.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: widget.controller,
              obscureText: hidden,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              validator: widget.validator,
              decoration: InputDecoration(
                hintText: widget.hint,
                suffixIcon: widget.obscure
                    ? IconButton(
                        tooltip: hidden ? 'Show password' : 'Hide password',
                        icon: Icon(
                          hidden ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => _hidden.value = !hidden,
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
