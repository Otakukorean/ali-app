import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/db/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await DatabaseHelper.instance.database;

  runApp(const AlghaifApp());
}
