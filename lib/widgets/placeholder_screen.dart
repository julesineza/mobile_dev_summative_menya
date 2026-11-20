import 'package:flutter/material.dart';

/// Temporary stand-in for screens owned by other members.
/// Replace it in app_routes.dart when your screen is ready.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
