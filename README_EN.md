# Astra 🚀

Astra is a modern Dart Web framework inspired by **FastAPI**.
It leverages Dart's **AOT compilation** performance and strong type system to provide excellent Developer Experience (DX).

[中文文档](README.md)

## ✨ Core Features

- **Intuitive Routing**: Define routes using annotations like `@Get`, `@Post`, similar to FastAPI/NestJS.
- **Dependency Injection (DI)**: Built-in powerful DI container supporting Singleton and Request-scoped patterns, automatically injecting Controller constructor dependencies.
- **Type-Safe Parameters**: Automatically parses and converts `@Path`, `@Query`, `@Body` parameters.
- **Smart Return Values**: Return DTO objects or `Future<T>` directly; the framework handles JSON serialization automatically.
- **Auto Documentation (OpenAPI)**: Out-of-the-box Swagger/OpenAPI support. Visit `/docs` to view beautiful API documentation (based on Redoc).
- **Zero Runtime Reflection**: Uses `build_runner` to generate code at compile time, fully supporting Dart AOT and Native deployment.
- **Middleware Support**: Compatible with the standard `shelf` middleware ecosystem.

## 📦 Installation

Add dependencies to `pubspec.yaml`:

```yaml
dependencies:
  astra: ^0.1.0
  shelf: ^1.4.0

dev_dependencies:
  build_runner: ^2.4.0
  # other generator dependencies...
```

## 🚀 Quick Start

### 1. Define Controller (`lib/src/user_controller.dart`)

```dart
import 'package:astra/astra.dart';
import 'package:shelf/shelf.dart';

part 'user_controller.g.dart'; // Reference generated file

// Define DTO
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
  
  // Dependency Injection (Assuming UserService is registered)
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

### 2. Run Code Generation

Run in terminal:

```bash
dart run build_runner build
```

This will generate `user_controller.g.dart`, containing route registration and DI factory code.

### 3. Create App Entry (`bin/main.dart`)

```dart
import 'package:astra/astra.dart';
import 'package:your_project/src/user_controller.dart'; 

void main() async {
  // 1. Initialize App and Dependencies
  final app = AstraApp(
    providers: [
      UserService(), // Register service
    ],
  );

  // 2. Register Controller (Use generated helper function)
  registerUserController(app);

  // 3. Start Server
  await app.listen(8080);
}
```

## 📚 API Documentation

After starting the service, visit:
- **API Docs UI**: `http://localhost:8080/docs`
- **OpenAPI JSON**: `http://localhost:8080/openapi.json`

## 🛠️ Exception Handling

Throw exceptions directly, and the framework automatically converts them to corresponding HTTP responses:

```dart
@Get('/error')
void testError() {
  throw BadRequestException('Invalid input'); // Returns 400
  // Or throw NotFoundException('User not found'); // Returns 404
}
```
