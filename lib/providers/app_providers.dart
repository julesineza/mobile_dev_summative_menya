import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'assessment_provider.dart';

/// Every feature's providers are registered here, wrapped around MaterialApp in main.dart.
/// Keep one list per feature so members rarely edit the same lines.
List<SingleChildWidget> get appProviders => [
      ...authProviders,
      ...studentProviders,
      ...assessmentProviders,
      ...reviewProviders,
    ];

// Replace these empty lists with real ChangeNotifierProviders as you build.
// Example: ChangeNotifierProvider(create: (_) => AssessmentProvider(repo))
List<SingleChildWidget> get authProviders => [];       // Member 1
List<SingleChildWidget> get studentProviders => [];    // Member 2
List<SingleChildWidget> get assessmentProviders => [
  ChangeNotifierProvider(create: (_) => AssessmentProvider()),
]; // Member 3
List<SingleChildWidget> get reviewProviders => [];     // Member 4
