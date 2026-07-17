---
name: shawn-jd-java-refactor
description: 按照团队规范进行 Java 代码两步重构：第一步提升健壮性和可读性，第二步提取魔法数字和魔法字符串为类内常量。Use when users ask to refactor Java code, reduce nested logic with guard clauses, replace fragile null/collection/string checks with agreed utility classes, reduce unnecessary lambda usage, or extract magic values.
---

# Java 两步重构

按照团队约定对 Java 代码做行为保持的重构。默认使用中文说明，代码、类名、方法名、包名和错误信息保持原文。

## 工作流程

1. 读取用户指定的 Java 文件或代码片段，先理解现有行为、依赖工具类和上下文约束。
2. 第一步重构：提升健壮性和可读性，优先降低嵌套、明确空值/集合/字符串判断、减少不必要的 lambda。
3. 第二步重构：识别魔法数字和魔法字符串，提取为类内 `private static final` 常量，并更新引用。
4. 修改后说明关键变化、行为保持点和需要用户自行运行的测试。

## 重构规则

- 优先使用卫语句减少深层 `if/else` 嵌套。
- 保持原有业务行为，不为了形式统一改变异常、返回值、日志、监控或调用顺序。
- 尽量减少 lambda 和 stream 链式调用；当普通循环更清晰或更符合团队规范时，改为常规循环。
- 尽量不创建新方法；确需提取时，控制子方法数量并保持命名具体。
- 避免引入项目中不存在的新依赖。只有在原项目已经使用相关工具类时，才主动替换为该工具类。
- 修改共享逻辑、边界条件或异常路径后，提醒用户运行对应单元测试或回归用例。

## 约定工具类

优先使用项目中已有的约定工具类：

- `Objects.isNull` / `Objects.nonNull`
- `CollectionUtils.isEmpty` / `CollectionUtils.isNotEmpty`
- `MapUtils.isEmpty` / `MapUtils.isNotEmpty`
- `StringUtils.isBlank` / `StringUtils.isNotBlank`
- `JSON.toJSONString`
- `Sets.newHashSet` / `Lists.newArrayList`
- `RequestUtil.reportUmp`
- `ConfigWareUtils.isOpen`

如果文件中没有对应 import，先判断项目是否已有该依赖；无法确认时，不要盲目新增 import。

## 魔法值处理

- 提取硬编码数字和字符串时，使用有业务含义的常量名。
- 常量放在类内字段区，通常使用 `private static final`。
- 不要提取明显无需命名的通用值，例如 `0`、`1`、`-1`，除非它们承载明确业务含义。
- 不要把日志模板、异常信息或协议字段机械提取成常量；只有重复出现或具有稳定业务语义时再提取。

## 输出要求

完成重构后，给出简短报告：

- 修改了哪些方法或逻辑块。
- 哪些魔法值被提取成常量。
- 哪些行为保持不变。
- 建议运行哪些测试或验证命令。

## Resources

- 需要更多示例、检查清单和常见重构模式时，读取 `references/refactor-patterns.md`。
