import 'package:flutter/material.dart';

import 'colors.dart';

class StudentColors {
  static const Color watch = Color.fromARGB(255, 218, 135, 58);
  static const Color watchFill = Color.fromARGB(255, 249, 237, 226);
}

extension StudentGreen on BuildContext {
  /// AppColors.button is too dark to read on the dark background,
  /// so dark mode uses a lighter green.
  Color get studentGreen => Theme.of(this).brightness == Brightness.dark
      ? const Color.fromARGB(255, 111, 208, 142)
      : AppColors.button;
}
