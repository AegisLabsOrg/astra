import 'package:astra/astra.dart';
import 'package:drift/drift.dart';
import 'database.dart';
import 'todo_controller.dart';
import 'websocket_controller.dart';

void main() async {
  // 1. 初始化 DB
  final db = AppDatabase();

  // 2. 初始化 Logger
  final logger = ConsoleLogger();

  // 3. 初始化 App (注入依赖)
  final app = AstraApp(providers: [db], middlewares: [requestLogger(logger)]);
  app.container.register<AstraLogger>(logger);

  // 3. 注册控制器
  // 注意：运行 `dart run build_runner build` 后，此函数才可用
  registerTodoController(app);
  registerWebSocketController(app);

  // 4. 启动服务
  await app.listen(3000);
  print('✨ Todo App running on http://localhost:3000');
  print('📚 Documentation: http://localhost:3000/docs');
}
