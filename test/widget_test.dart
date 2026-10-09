import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:alghaif/core/db/database_helper.dart';
import 'package:alghaif/screens/login_screen.dart';
import 'package:alghaif/services/constants_service.dart';
import 'package:alghaif/services/site_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.debugDatabasePathOverride = inMemoryDatabasePath;
  });

  testWidgets('Login screen shows username and password fields', (
    tester,
  ) async {
    await tester.runAsync(() => DatabaseHelper.instance.database);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اسم المستخدم'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  test('Constants are linked to a selected site and number', () async {
    final db = await DatabaseHelper.instance.database;
    final site = (await SiteService.instance.getSites()).first;
    final number11100 = await SiteService.instance.findNumberForSite(
      site.id,
      '11100',
    );
    final number11101 = await SiteService.instance.findNumberForSite(
      site.id,
      '11101',
    );

    await ConstantsService.instance.addEntry(
      name: 'Linked entry',
      phone: '123',
      ip: '192.168.1.2',
      siteId: site.id,
      siteNumberId: number11100!.id,
      number: '11100',
    );
    await ConstantsService.instance.addEntry(
      name: 'Other entry',
      phone: '456',
      ip: '192.168.1.3',
      siteId: site.id,
      siteNumberId: number11101!.id,
      number: '11101',
    );

    final entries = await ConstantsService.instance.getEntries(
      siteNumberId: number11100.id,
    );

    expect(await db.getVersion(), 8);
    expect(entries, hasLength(1));
    expect(entries.single.name, 'Linked entry');
    expect(entries.single.number, '11100');

    await ConstantsService.instance.updateEntry(
      id: entries.single.id,
      name: 'Updated entry',
      phone: '789',
      ip: '192.168.1.20',
    );
    final updatedEntries = await ConstantsService.instance.getEntries(
      siteNumberId: number11100.id,
    );
    expect(updatedEntries.single.name, 'Updated entry');
    expect(updatedEntries.single.ip, '192.168.1.20');
  });

  test(
    'Seeder creates numbers for every prefix and search uses the table',
    () async {
      final site = (await SiteService.instance.getSites()).first;
      final prefixes = await SiteService.instance.getPrefixesForSite(site.id);
      final seededNumbers = <String>[];
      for (final prefix in prefixes) {
        final numbers = await SiteService.instance.getNumbersForPrefix(
          prefix.id,
        );
        expect(numbers, hasLength(100));
        seededNumbers.addAll(numbers.map((number) => number.number));
      }

      expect(seededNumbers, hasLength(prefixes.length * 100));
      expect(
        (await SiteService.instance.findNumberForSite(
          site.id,
          '10000',
        ))?.number,
        '10000',
      );
      expect(
        await SiteService.instance.findNumberForSite(site.id, '99999'),
        isNull,
      );

      final number = await SiteService.instance.findNumberForSite(
        site.id,
        '10000',
      );
      final constants = await ConstantsService.instance.getNumberConstants(
        number!.id,
      );
      expect(constants.imagePath, isNull);
      await ConstantsService.instance.updateNumberConstants(
        id: constants.id,
        ip: '10.0.0.1',
        whatsapp: '07700000000',
        landline: '123456',
      );
      final updated = await ConstantsService.instance.getNumberConstants(
        number.id,
      );
      expect(updated.ip, '10.0.0.1');
      expect(updated.whatsapp, '07700000000');
      expect(updated.landline, '123456');
    },
  );
}
