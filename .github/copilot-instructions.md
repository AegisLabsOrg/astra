# Astra 项目指南

这一份指南旨在帮助 AI 助手（如 Copilot）理解 **Astra** 项目。Astra 是一个由经验丰富的开发者构建的 Dart Web 服务框架，灵感来源于 **Python FastAPI**。

## 核心理念
- **FastAPI 般的体验**：追求极简的样板代码、高性能和直观的 API。
- **Dart 原生**：充分利用 Dart 的强类型系统、`Future`/`Stream` 和 Isolates。
- **开发者体验 (DX)**：通过强类型和自动补全实现“开箱即用”。

## 架构准则

### 1. 路由与处理 (Routing & Handling)
- 使用 **注解 (Annotations/Macros)** 定义路由，类似 FastAPI 的装饰器。
  - 示例：`@Get('/users')`，`@Post('/users')`。
- Handler 应返回类型化的对象、`Response` 对象或 `Future<T>`。
- 支持通过参数名或类型自动注入路径参数 (Path Params) 和查询参数 (Query Params)。

### 2. 数据验证与序列化
- 输入数据 (JSON Body) 应自动解析为 Dart 类 (DTOs)。
- 区分请求 (Request) 和响应 (Response) 的 DTO 模型。
- **核心技术**：强制使用 **Dart Macros (Dart 3.10+)** 进行序列化和路由元数据处理。
  - **优势**：零运行时开销 (对 AOT 友好)，无需 `build_runner` 或文件监听器。实现“写完即跑”的体验。

### 3. 依赖注入 (Dependency Injection)
- 实现分层依赖注入系统，不仅支持单例，也要支持请求级作用域 (Scoped)。
- 参数注入应基于类型自动从容器中解析。

## 编码规范
- **风格**：严格遵循 lint 规则。
- **异步**：统一使用 `async`/`await`。
- **错误处理**：使用自定义异常映射到 HTTP 状态码 (例如：抛出 `ValidationException` -> 自动返回 400)。
- **文档**：所有公共 API 必须包含 Dartdoc 注释。

## 技术栈推荐
- **运行时**：Dart (Server-side)。
- **核心库**：基于 `shelf` 进行封装 (为了稳定性)，但在其上提供更高级的抽象。
- **测试**：使用 `test` 包，强调端点 (Endpoint) 的集成测试。

## 用户画像
用户是一位拥有 11 年经验的高级工程师，Flutter 专家。
- **不要**解释基础的 Dart 语法。
- **重点关注**架构决策、高级设计模式和元编程 (Macros) 的实现细节。
