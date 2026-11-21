import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'assessment_provider.dart';
import 'settings_provider.dart';
import '../services/preferences_service.dart';

/// Builds the full provider list, wiring [PreferencesService] into
/// [SettingsProvider] and seeding [AssessmentProvider] with the saved active class.
///
/// Call this from [main.dart] after [PreferencesService.init()] has completed.
List<SingleChildWidget> buildProviders(PreferencesService prefs) => [
      ...authProviders,
      ...studentProviders,
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(prefs),
      ),
      ChangeNotifierProxyProvider<SettingsProvider, AssessmentProvider>(
        create: (_) =>
            AssessmentProvider(initialClassName: prefs.activeClass),
        update: (_, settings, previous) {
          // Keep provider in sync when the active class changes (e.g. user picks a new class).
          final provider = previous ?? AssessmentProvider(initialClassName: settings.activeClass);
          if (provider.selectedClassName != settings.activeClass &&
              settings.activeClass.isNotEmpty) {
            provider.syncClassFromSettings(settings.activeClass);
          }
          return provider;
        },
      ),
      ...reviewProviders,
    ];

// ── Per-feature provider lists (kept separate so each member rarely conflicts) ──

/// Auth providers — owned by Member 1.
List<SingleChildWidget> get authProviders => [];

/// Student / class analytics providers — owned by Member 2.
List<SingleChildWidget> get studentProviders => [];

/// Post-assessment review providers — owned by Member 4.
List<SingleChildWidget> get reviewProviders => [];
