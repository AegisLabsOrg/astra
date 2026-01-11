# Astra 架构设计

## 1. 概览
Astra 是一个基于 `shelf` 标准构建的请求-响应框架，目标是抽象掉底层的 `Request`/`Response` 对象，转而提供强类型的参数注入和返回值处理，带来类似 FastAPI 的开发体验。

## 2. 核心概念

### A. 应用主体 (`AstraApp`)
这是框架的中心枢纽，包含：
- **依赖注入器** (Root Container)：管理全局服务。
- **路由器** (Router)：管理路由树。
- **中间件管道** (Middleware Pipeline)：处理请求拦截。

### B. 编译时路由生成 (Compile-Time Routing Generation)
我们使用 `build_runner` 和 `source_gen` (基于 `analyzer`) 代替实验性的 Dart Macros，来实现稳定的元编程能力，确保在所有 Dart 平台 (包括 AOT) 生效。

**核心模式：**
1.  **开发者**：编写带有 `@Controller` 注解的类和方法。
2.  **ControllerGenerator**：`build_runner` 扫描代码，生成 `controller.g.dart` 文件。
    - 为每个 Controller 生成一个 `registerRoutes` 扩展方法，负责参数解析、类型转换和路由注册。
    - 生成依赖注入工厂代码，自动解析构造函数依赖。
3.  **应用启动**：应用启动时调用生成的工厂方法，将控制器注册到 `AstraApp` 的路由器中。

### C. 依赖注入 (DI) 系统
设计灵感来自 FastAPI 的 `Depends`。
- **作用域 (Scope)**：
    - `Singleton` (单例)：全应用共享。
    - `Scoped` (请求级)：每个请求创建一个新实例。
- **解析策略**：
    - 基于类型的自动构造函数注入。
    - 专用注入器：`@Query` (查询参数), `@Path` (路径参数), `@Body` (请求体)。

### D. 数据传输对象 (DTO)
- 使用标准 Dart 类定义 DTO。
- 通过 `json_serializable` 或手动编写 `fromJson`。
- 框架在生成器中自动生成 `jsonDecode` 和转换代码，在数据到达 Handler 之前完成 `JSON -> Object` 的转换。

## 3. 数据流 (Data Flow)

```mermaid
graph LR
    Req[原始请求] --> Middleware
    Middleware --> Router[路由匹配]
    Router --> Context[上下文(Context)创建]
    Context --> DI[依赖/参数解析]
    DI --> Guard[守卫/认证]
    Guard --> Handler[用户业务逻辑]
    Handler --> Result[类型化结果]
    Result --> Serialize[JSON 序列化]
    Serialize --> Res[HTTP 响应]
```

## 4. 预期的 API 体验 (Developer Experience)

```dart
// main.dart
import 'package:astra/astra.dart';
import 'src/user_controller.dart';

void main() async {
  final app = AstraApp(
    controllers: [
      UserController(),
    ],
    providers: [
      DatabaseService(), // 注册依赖服务
    ],
  );
  
  await app.listen(8080);
}
```

```dart
// src/user_controller.dart
@Controller('/users')
class UserController {
  
  // 通过构造函数进行依赖注入
  final DatabaseService db;
  UserController(this.db); 

  @Get('/:id')
  Future<UserResponse> getUser(
    @Path() String id, 
    @Query() bool details = false
  ) async {
    return db.findUser(id, withDetails: details);
  }

  @Post('/')
  Future<UserResponse> createUser(@Body() CreateUserDto body) async {
    // 此时 body 已经被验证通过，且是强类型的对象
    return db.create(body);
  }
}
```

## 5. 模块架构详解 (Module Architecture)

Astra 的代码库设计为模块化结构，旨在复刻 FastAPI 的分层架构体验。

### A. 核心运行时 (`lib/src`)

这些模块构成了用户应用运行的基础设施。

| 模块名称 | 路径建议 | 职责描述 (对应 Python 生态) |
| :--- | :--- | :--- |
| **App Core** | `core/` | **(Starlette)** 框架的心脏。包含 `AstraApp` 类。负责启动 HTTP 服务器 (基于 shelf)、管理生命周期、全局异常捕获。 |
| **Routing** | `routing/` | 维护路由树 (Trie-based)。它不解析参数，只负责高效地通过 URL 找到对应的 Handler。 |
| **DI System** | `di/` | **(FastAPI Depends)** 强大的依赖注入容器。支持 `Singleton` (单例) 和 `Scoped` (请求隔离) 模式。负责自动实例化 Controller 并注入依赖。 |
| **HTTP Layer** | `http/` | **(Request/Response)** 适配层。屏蔽底层 `shelf` 细节，提供更友好的 `Context` 对象，处理 Cookie、Header 解析。 |
| **OpenAPI** | `openapi/` | **(Swagger UI)** 核心特性。负责收集元数据并在运行时提供 `/openapi.json` 和 Redoc 文档 (`/docs`)。自动集成到路由生成流程中。 |
| **Generator** | `generator/` | **(Type System)** 该框架的引擎。包含 `ControllerGenerator`，基于 `build_runner` 在编译时生成路由注册代码、参数解析、类型转换和依赖注入工厂，实现“零运行时开销”。 |
| **Validation** | `validation/` | **(Pydantic)** 数据验证层。提供如 `@Min`, `@Email` 等注解，配合 DTO 宏自动拦截非法数据。 |

### B. CLI 工具模块 (`lib/src/cli` & `bin/`)

CLI 是 Astra 库的一等公民，直接集成在包中。

- **定位**：类似于 `fastapi-cli` 或 `uvicorn`。
- **入口**：`bin/astra.dart` (用户通过 `dart run astra <command>` 调用)。
- **核心功能**：
    1.  **`dev` (开发服务器)**：启动应用，并监听文件变化进行**热重载 (Hot Reload)**，提供丝滑的开发体验。
    2.  **`create` (脚手架)**：快速生成符合 Astra 架构规范的新项目包含。
    3.  **`inspect` (调试工具)**：分析代码中的宏生成结果，打印当前的路由表结构。

### C. 后续路线图 (Roadmap)

为了进一步提升 "Dart 版 FastAPI" 的体验，我们计划支持：

| 模块名称 | 路径建议 | 职责描述 |
| :--- | :--- | :--- |
| **Response Model** | `generator/` | **(Output Filters)** 允许 Handler 定义返回类型 (Response DTO)。框架应自动过滤掉未定义的字段 (例如在 DTO 中剔除 `User.password`)。 |
| **CLI Tools** | `cli/` | **(Dev Server)** 完善的 CLI 工具，支持热重载和项目脚手架。 |
