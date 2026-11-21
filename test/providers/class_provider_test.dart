import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_dev_summative_menya/models/school_class.dart';
import 'package:mobile_dev_summative_menya/providers/class_provider.dart';
import 'package:mobile_dev_summative_menya/providers/settings_provider.dart';
import 'package:mobile_dev_summative_menya/services/school_class_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSchoolClassService extends Mock implements SchoolClassService {}

SchoolClass makeClass(String id, String name) =>
    SchoolClass(id: id, schoolId: 's1', teacherId: 'u1', name: name, grade: 3);

void main() {
  late MockSchoolClassService service;
  late StreamController<List<SchoolClass>> classEvents;
  late SettingsProvider settings;
  late ClassProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsProvider(await SharedPreferences.getInstance());
    service = MockSchoolClassService();
    classEvents = StreamController<List<SchoolClass>>();
    when(() => service.watchMyClasses('u1'))
        .thenAnswer((_) => classEvents.stream);
    provider = ClassProvider(service)..configure(uid: 'u1', settings: settings);
  });

  tearDown(() async {
    provider.dispose();
    await classEvents.close();
  });

  test('selects the first class by default', () async {
    classEvents.add([makeClass('a', 'P3-A'), makeClass('b', 'P3-B')]);
    await Future<void>.delayed(Duration.zero);

    expect(provider.classes, hasLength(2));
    expect(provider.selectedClass?.id, 'a');
  });

  test('select() saves the choice and changes the selected class', () async {
    classEvents.add([makeClass('a', 'P3-A'), makeClass('b', 'P3-B')]);
    await Future<void>.delayed(Duration.zero);

    await provider.select('b');

    expect(provider.selectedClass?.id, 'b');
    expect(settings.selectedClassId, 'b');
  });

  test(
    'falls back to the first class when the selected one is deleted',
    () async {
      classEvents.add([makeClass('a', 'P3-A'), makeClass('b', 'P3-B')]);
      await Future<void>.delayed(Duration.zero);
      await provider.select('b');

      classEvents.add([makeClass('a', 'P3-A')]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedClass?.id, 'a');
    },
  );
}
