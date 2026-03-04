import 'dart:io';
import 'package:drift/drift.dart';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart';

part 'database.g.dart';

// 1. Define Tables
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

// 2. Define Database Class
@DriftDatabase(tables: [Todos])
class AppDatabase extends _$AppDatabase {
  // Pass the executor to the super constructor
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// 3. Connect to Postgres
QueryExecutor _openConnection() {
  return PgDatabase(
    endpoint: Endpoint(
      host: Platform.environment['DB_HOST'] ?? 'localhost',
      port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
      database: Platform.environment['DB_NAME'] ?? 'astra_todo',
      username: Platform.environment['DB_USER'] ?? 'postgres',
      password: Platform.environment['DB_PASS'] ?? 'password',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );
}
