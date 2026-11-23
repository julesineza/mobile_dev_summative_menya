import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/core/constants/colors.dart';
import 'package:mobile_dev_summative_menya/models/enums.dart';
import 'package:mobile_dev_summative_menya/models/student.dart';
import 'package:mobile_dev_summative_menya/widgets/student_widgets.dart';

const _samir = Student(
  id: '3',
  schoolId: 'sch1',
  classId: 'c1',
  name: 'Samir Ali',
  rollNo: 12,
  status: SupportStatus.needsSupport,
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('initialsOf', () {
    test('two names → two initials', () {
      expect(initialsOf('nawaf ahmed'), 'NA');
    });

    test('one name → one initial', () {
      expect(initialsOf('Khalid'), 'K');
    });

    test('three names → only first two', () {
      expect(initialsOf('Samir Ali Hassan'), 'SA');
    });

    test('extra spaces are ignored', () {
      expect(initialsOf('  Jules   Verne  '), 'JV');
    });

    test('empty name does not crash', () {
      expect(initialsOf(''), '');
      expect(initialsOf('   '), '');
    });
  });

  group('lastAssessedLabel', () {
    test('null → not assessed', () {
      expect(lastAssessedLabel(null), 'Not assessed yet');
    });

    test('today', () {
      expect(lastAssessedLabel(DateTime.now()), 'Last assessed today');
    });

    test('yesterday', () {
      final d = DateTime.now().subtract(const Duration(days: 1));
      expect(lastAssessedLabel(d), 'Last assessed yesterday');
    });

    test('several days ago', () {
      final d = DateTime.now().subtract(const Duration(days: 5));
      expect(lastAssessedLabel(d), 'Last assessed 5d ago');
    });
  });

  test('every status has a label', () {
    expect(SupportStatus.onTrack.label, 'On track');
    expect(SupportStatus.watch.label, 'Watch');
    expect(SupportStatus.needsSupport.label, 'Needs support');
  });

  test('every response level has a label', () {
    expect(ResponseLevel.struggling.label, 'Struggling');
    expect(ResponseLevel.developing.label, 'Developing');
    expect(ResponseLevel.proficient.label, 'Proficient');
  });

  group('StatusBadge', () {
    for (final status in SupportStatus.values) {
      testWidgets('${status.name} shows its label in capitals', (
        tester,
      ) async {
        await _pump(tester, StatusBadge(status: status));

        expect(find.text(status.label.toUpperCase()), findsOneWidget);
      });
    }

    testWidgets('text uses the status colour', (tester) async {
      await _pump(tester, const StatusBadge(status: SupportStatus.watch));

      final text = tester.widget<Text>(find.text('WATCH'));
      final context = tester.element(find.byType(StatusBadge));
      expect(text.style?.color, SupportStatus.watch.colorOf(context));
    });
  });

  group('StudentAvatar', () {
    testWidgets('shows the initials', (tester) async {
      await _pump(tester, const StudentAvatar(name: 'nawaf ahmed'));

      expect(find.text('NA'), findsOneWidget);
    });

    testWidgets('no status → no dot', (tester) async {
      await _pump(tester, const StudentAvatar(name: 'Khalid'));

      expect(find.byType(Positioned), findsNothing);
    });

    testWidgets('with a status → shows a dot in that colour', (tester) async {
      await _pump(
        tester,
        const StudentAvatar(name: 'Khalid', status: SupportStatus.onTrack),
      );

      final dot = find.descendant(
        of: find.byType(Positioned),
        matching: find.byType(Container),
      );
      expect(dot, findsOneWidget);
      final context = tester.element(find.byType(StudentAvatar));
      final decoration =
          tester.widget<Container>(dot).decoration! as BoxDecoration;
      expect(decoration.color, SupportStatus.onTrack.colorOf(context));
    });
  });

  group('FilterPill', () {
    testWidgets('shows the label and calls onTap when tapped', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        FilterPill(label: 'Watch (1)', selected: false, onTap: () => taps++),
      );

      expect(find.text('Watch (1)'), findsOneWidget);
      await tester.tap(find.text('Watch (1)'));
      expect(taps, 1);
    });

    testWidgets('selected pill uses the button colours', (tester) async {
      await _pump(
        tester,
        FilterPill(label: 'All (4)', selected: true, onTap: () {}),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(FilterPill),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, AppColors.button);
      final text = tester.widget<Text>(find.text('All (4)'));
      expect(text.style?.color, AppColors.onButton);
    });

    testWidgets('unselected pill does not use the button colour', (
      tester,
    ) async {
      await _pump(
        tester,
        FilterPill(label: 'All (4)', selected: false, onTap: () {}),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(FilterPill),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, isNot(AppColors.button));
    });
  });

  group('StudentRow', () {
    testWidgets('shows name, subtitle, initials and a chevron', (
      tester,
    ) async {
      await _pump(
        tester,
        const StudentRow(student: _samir, subtitle: 'Class P4 Blue'),
      );

      expect(find.text('Samir Ali'), findsOneWidget);
      expect(find.text('Class P4 Blue'), findsOneWidget);
      expect(find.text('SA'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      // Status dot on the avatar.
      expect(
        find.descendant(
          of: find.byType(StudentAvatar),
          matching: find.byType(Positioned),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping the row calls onTap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        StudentRow(student: _samir, subtitle: 'x', onTap: () => taps++),
      );

      await tester.tap(find.text('Samir Ali'));
      expect(taps, 1);
    });

    testWidgets('a long subtitle stays on one line without overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 250,
          child: StudentRow(student: _samir, subtitle: 'very long ' * 30),
        ),
      );

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.textContaining('very long'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });

  group('SyncErrorBanner', () {
    testWidgets('shows nothing when message is null', (tester) async {
      await _pump(tester, const SyncErrorBanner(message: null));

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows the message and error icon', (tester) async {
      await _pump(tester, const SyncErrorBanner(message: 'Could not save.'));

      expect(find.text('Could not save.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('no close button without onDismiss', (tester) async {
      await _pump(tester, const SyncErrorBanner(message: 'Could not save.'));

      expect(find.byTooltip('Dismiss'), findsNothing);
    });

    testWidgets('close button calls onDismiss', (tester) async {
      var dismissed = false;
      await _pump(
        tester,
        SyncErrorBanner(
          message: 'Could not save.',
          onDismiss: () => dismissed = true,
        ),
      );

      await tester.tap(find.byTooltip('Dismiss'));
      expect(dismissed, isTrue);
    });
  });

  testWidgets('MenyaCard shows its child', (tester) async {
    await _pump(tester, const MenyaCard(child: Text('Inside')));

    expect(find.text('Inside'), findsOneWidget);
  });

  testWidgets('widgets also build in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Column(
            children: [
              const StatusBadge(status: SupportStatus.needsSupport),
              const StudentRow(student: _samir, subtitle: 'Class P4 Blue'),
              FilterPill(label: 'All', selected: true, onTap: () {}),
              const SyncErrorBanner(message: 'Oops'),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('NEEDS SUPPORT'), findsOneWidget);
    expect(find.text('Oops'), findsOneWidget);
  });
}
