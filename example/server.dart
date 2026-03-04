import 'package:astra_dart/astra.dart';
import 'database.dart';
import 'todo_controller.dart';
import 'websocket_controller.dart';
import 'auth_controller.dart';

void main() async {
  // 1. 初始化 DB
  final db = AppDatabase();

  // 2. 初始化 Logger
  final logger = ConsoleLogger();

  // 3. 初始化 Auth
  final authService = SimpleAuthService('hidden_secret');

  // 4. 初始化 App (注入依赖)
  final app = AstraApp(
    providers: [db, authService],
    middlewares: [
      requestLogger(logger),
      // 启用认证拦截，白名单放行文档和登录接口
      authMiddleware(
        authService,
        whitelist: ['/docs', '/openapi.json', '/auth/login'],
      ),
    ],
  );
  app.container.register<AstraLogger>(logger);

  // 5. 注册控制器
  // 注意：运行 `dart run build_runner build` 后，此函数才可用
  registerTodoController(app);
  registerWebSocketController(app);
  registerAuthController(app);

  // 6. 启动服务
  await app.listen(3000);
  logger.info('✨ Todo App running on http://localhost:3000');
  logger.info('📚 Documentation: http://localhost:3000/docs');
}
