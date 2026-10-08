import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:alghaif/core/db/database_helper.dart';
import 'package:alghaif/screens/login_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.debugDatabasePathOverride = inMemoryDatabasePath;
  });

  testWidgets('Login screen shows username and password fields', (tester) async {
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
}
