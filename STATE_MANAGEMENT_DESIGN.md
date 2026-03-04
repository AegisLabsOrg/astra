# 状态管理设计思路（设计总结）

> **状态管理 = 带一致性语义的缓存（State） + 依赖追踪（Dependency Graph） + 调度器（Scheduler） + 生命周期管理（Lifecycle） + 副作用模型（Effects） + 可观测性（Observability）**。
>
> UI 绑定（Widget/Element 生命周期）只是其中一层适配器，不应与内核耦合。

---

## 1. 核心分层（强烈建议）

### 1) 内核（UI 无关）
负责：
- 缓存最新值（replay latest）
- 派生/依赖追踪
- 一致性与调度（批处理、事务、拓扑顺序）
- 生命周期（autoDispose/keepAlive、资源回收）
- 异步竞争处理（generation/version）
- override/scope（测试/多环境）

### 2) UI 适配层（Flutter binding）
负责：
- mount 时订阅、dispose 时取消订阅
- 将“值变化”转换成局部 rebuild 或副作用回调
- 处理 `didUpdateWidget` / `didChangeDependencies` 时的订阅更新

> 结论：内核应该可在非 UI 环境复用（测试/后台任务/服务端），UI 层只是 adapter。

---

## 2. 最重要的语义分离：State vs Event/Effect

### State（可重放）
语义：任何时候订阅都能**立刻拿到最新值**；late subscriber 不需要历史通知。
- 典型用途：UI 渲染、派生计算、缓存结果
- 核心约束：订阅时必须 “emit current” 一次（replay latest）

### Event / Effect（一次性/副作用）
语义：默认**不重放**；如需重放必须显式选择策略。
- 典型用途：toast、导航、弹窗、埋点、一次性提示、命令式动作
- 建议内建策略（用类型或配置明确化）：
  - `drop`：无人订阅即丢（默认安全）
  - `bufferN`：环形缓冲 N 条
  - `ttl`：保留最近 X 秒
  - `cursor/offset`：按订阅者游标精确消费（成本最高、语义最强）

> 你之前遇到的“组件不存在时通知暂存/什么时候消费”的难题，根因通常是把 **event 当成 state**。

---

## 3. 一致性模型（决定调度器与可预测性）

建议默认：**批处理一致（batched consistency）**。

### 写入与传播
- 写入：只标记 dirty，不立即级联重算
- flush：在 microtask/frame/显式 `flush()` 时统一重算

### 推荐承诺（设计目标）
- 同一轮 flush 内读取视图一致（snapshot/version）
- 同一节点一轮最多重算一次（去重）
- 支持“事务”：多次写合并为一次传播

备选：同步一致（实现更简单，但更容易抖动/重复计算/顺序敏感）。

---

## 4. 依赖追踪（实现“最小重算集”的关键）

必须回答：

### 依赖边如何产生？
- 动态收集：在 build/compute 期间通过 `watch()` 记录依赖边
- 静态声明：通过元数据/生成方式预先声明依赖（不依赖特定技术）

### 依赖边如何维护？
- 每次 build/compute 完成，用“新依赖集”替换旧依赖集
- 解绑旧边、绑定新边（避免依赖关系漂移导致泄漏与错误传播）

### 传播规则
- 上游变更 → 下游标 dirty → 调度器统一重算（拓扑顺序）

目标：避免“全局广播”，做到**最小传播/最小重建**。

---

## 5. 生命周期（缓存与资源的边界）

### 缓存型 State
- 无人订阅时可保留 latest（更像缓存）

### 资源型节点（stream/timer/socket/db 等）
- 必须支持 `onDispose`
- autoDispose 推荐采用 **延迟 sweep**（防抖回收）
- 提供 keepAlive / 引用计数策略

实用原则：
- State 的生命周期偏“缓存”
- Effect/IO 的生命周期偏“资源”

---

## 6. 异步语义（必须从第一天就设计）

通用做法：**generation/version gating**。

- 每次触发重算生成 `generationId`
- Future/Stream 完成时仅在 generation 匹配时提交结果
- 过期结果丢弃或记录（用于诊断）

目标：消灭“旧结果覆盖新状态”的竞态。

---

## 7. API 设计建议（最小可扩展内核）

建议至少具备：
- `State<T>`：可写、可读、replay latest
- `Computed<T>`：派生状态，带依赖追踪
- `Effect<E>`：事件流（明确投递语义）
- `Scope/Container`：缓存槽位、override、生命周期边界
- `Scheduler`：dirty 标记、flush、去重、拓扑顺序

访问语义建议明确分为三类：
- `watch`：建立依赖（用于派生与 UI 重建）
- `read`：不建依赖（一次性读取）
- `listen`：不重建，仅副作用回调

---

## 8. 可观测性（决定能否长期维护/优化）

建议内建诊断钩子（至少 debug 模式）：
- 本轮 flush 重算了哪些节点、耗时
- 某个重建/重算的原因链路（哪个依赖变了）
- dirty 传播路径
- 异步过期结果统计

> 工程上，“解释为什么更新了”往往比“更快 5%”更有价值。

---

## 9. 设计自检清单（开工前必过）

1. late subscriber 是否无需历史通知即可正确渲染？（State replay latest）
2. Event 是否有明确投递语义？（drop/buffer/ttl/cursor）
3. 是否定义了 flush 边界与一致性承诺？（batched / transaction）
4. 是否能做到最小重算集？（依赖追踪与传播）
5. 异步是否不会被过期结果污染？（generation/version）
6. 生命周期是否能稳定回收资源且不抖动？（sweep + keepAlive）
7. 是否能解释“为什么更新了”？（observability）

---

## 10. 后续建议：实现路线（可选）

如果你准备动手实现，建议按最小闭环分阶段：

1. 只实现 `State<T>`（replay latest）+ 订阅生命周期（subscribe/unsubscribe）
2. 加入 `Computed<T>`（依赖追踪 + dirty）
3. 引入 `Scheduler`（batching/flush 去重 + 拓扑顺序）
4. 加入 `Effect<E>`（drop 与 bufferN 至少一个）
5. 加入 async generation（Future/Stream 派生）
6. 做最小可观测性（recompute reason / perf）

