import 'package:astra/astra.dart';
import 'package:astra/src/routing/route.dart';
import 'package:drift/drift.dart' hide Query;
import 'package:shelf/shelf.dart';
import 'database.dart'; // Import Database
import 'models.dart';
import 'dart:convert';

part 'todo_controller.g.dart';

@Controller('/todos')
class TodoController {
  final AppDatabase db; // Inject Database directly
  final AstraLogger logger;

  TodoController(this.db, this.logger);

  @Get('/')
  Future<List<Todo>> getAll() {
    logger.info('Getting all todos');
    return db.select(db.todos).get();
  }

  @Post('/')
  Future<Todo> create(@Body() CreateTodoDto body) async {
    // Use DTO for input
    logger.info('Creating todo: ${body.title}');

    // Convert DTO to Companion for Insert
    final companion = TodosCompanion.insert(
      title: body.title,
      completed: const Value(false),
    );

    // Insert returns the Row ID
    final id = await db.into(db.todos).insert(companion);

    // Return the new object
    return (db.select(db.todos)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  @Get('/:id')
  Future<Todo?> getById(@Path() String id) {
    return (db.select(
      db.todos,
    )..where((tbl) => tbl.id.equals(int.parse(id)))).getSingleOrNull();
  }

  @Delete('/:id')
  Future<void> delete(@Path() String id, @Query() bool force) async {
    if (!force) {
      logger.warning('Delete not forced');
      return;
    }
    await (db.delete(
      db.todos,
    )..where((tbl) => tbl.id.equals(int.parse(id)))).go();
  }
}
