# Astra 🚀

Astra 是一个受 **FastAPI** 启发的现代 Dart Web 框架。
它利用 Dart 的 **AOT 编译**性能和强类型系统，提供极佳的开发者体验 (DX)。

## ✨ 核心特性

- **直观的路由定义**：使用 `@Get`, `@Post` 等注解定义路由，类似 FastAPI/NestJS。
- **依赖注入 (DI)**：内置强大的 DI 容器，支持单例和请求级作用域，自动注入 Controller 构造函数依赖。
- **类型安全参数**：自动解析并转换 `@Path`, `@Query`, `@Body` 参数。
- **智能返回值**：直接返回 DTO 对象或 `Future<T>`，框架自动处理 JSON 序列化。
- **自动文档 (OpenAPI)**：开箱即用的 Swagger/OpenAPI 支持，访问 `/docs` 即可查看漂亮的 API 文档 (基于 Redoc)。
- **零运行时反射**：使用 `build_runner` 在编译时生成代码，完美支持 Dart AOT 和 Native 部署。
- **中间件支持**：兼容标准 `shelf` 中间件 ecosystem。

## 📦 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  astra: ^0.1.0
  shelf: ^1.4.0

dev_dependencies:
  build_runner: ^2.4.0
  # 其他生成器依赖...
```

## 🚀 快速开始

### 1. 定义 Controller (`lib/src/user_controller.dart`)

```dart
import 'package:astra/astra.dart';
import 'package:shelf/shelf.dart';

part 'user_controller.g.dart'; // 引用生成的文件

// 定义 DTO
class UserDto {
  final String name;
  final String email;
  UserDto({required this.name, required this.email});
  
  Map<String, dynamic> toJson() => {'name': name, 'email': email};
  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    name: json['name'], 
    email: json['email']
  );
}

@Controller('/users')
class UserController {
  
  // 依赖注入 (假设 UserService 已注册)
  final UserService userService;
  UserController(this.userService);

  @Get('/:id')
  Future<UserDto> getUser(@Path() String id, @Query() bool details) async {
    return userService.findUser(id, details: details);
  }

  @Post('/')
  Future<UserDto> createUser(@Body() UserDto body) async {
    return userService.create(body);
  }
}
```

### 2. 运行代码生成

在终端运行：

```bash
dart run build_runner build
```

这将生成 `user_controller.g.dart`，其中包含路由注册和依赖注入的工厂代码。

### 3. 创建应用入口 (`bin/main.dart`)

```dart
import 'package:astra/astra.dart';
import 'package:your_project/src/user_controller.dart'; 

void main() async {
  // 1. 初始化 App 和依赖
  final app = AstraApp(
    providers: [
      UserService(), // 注册服务
    ],
  );

  // 2. 注册 Controller (使用生成的辅助函数)
  registerUserController(app);

  // 3. 启动服务器
  await app.listen(8080);
}
```

## 📚 API 文档

启动服务后，访问：
- **API 文档 UI**: `http://localhost:8080/docs`
- **OpenAPI JSON**: `http://localhost:8080/openapi.json`

## 🛠️ 异常处理

直接抛出异常，框架会自动转换为对应的 HTTP 响应：

```dart
@Get('/error')
void testError() {
  throw BadRequestException('Invalid input'); // 返回 400
  // 或者 throw NotFoundException('User not found'); // 返回 404
}
```

