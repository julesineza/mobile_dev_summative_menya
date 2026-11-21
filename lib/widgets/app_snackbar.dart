import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
