---
name: shawn-java-refactor
version: 1.0.0
description: 按照团队规范进行Java代码两步重构，第一步提升健壮性和可读性，第二步处理魔法值
allowed-tools: Read, Edit, Grep, Glob, Bash
---

# Java两步重构技能

## 概述
这个技能按照指定的团队规范，对Java代码进行两步重构：
1. 第一步：提升代码健壮性与可读性，使用卫语句，限制lambda使用，使用指定工具类
2. 第二步：将魔法值提取为类内常量

## 重构规则

### 第一步规则
- ✅ 提升代码健壮性与可读性
- ✅ 尽量使用卫语句（Guard Clauses）
- ✅ 尽量不要使用lambda表达式
- ✅ 尽量不要创建新方法，如需创建不超过3个子方法
- ✅ 使用指定的工具类进行空值和集合判断

### 第二步规则
- ✅ 识别魔法值（Magic Numbers/Strings）
- ✅ 提取为类内常量，使用合适的命名规范

## 使用流程

### 开始重构
1. 用户指定需要重构的Java文件
2. 技能读取文件内容
3. 执行第一步重构，显示进度和勾选
4. 执行第二步重构，显示进度和勾选
5. 生成重构完成报告

### 第一步重构内容
- 使用卫语句替换嵌套if-else
- 使用指定工具类替换原始判断
- 简化lambda表达式为常规代码
- 优化代码结构但保持行为不变

### 第二步重构内容
- 扫描所有魔法值（硬编码的数字、字符串）
- 提取为private static final常量
- 更新所有引用位置

## 工具类使用规范

### 空值判断
```java
// 对象非空
if (Objects.nonNull(obj)) { ... }

// 对象为空
if (Objects.isNull(obj)) { ... }
```

### 集合判断
```java
// 集合非空
if (CollectionUtils.isNotEmpty(list)) { ... }

// 集合为空
if (CollectionUtils.isEmpty(list)) { ... }

// Map非空
if (MapUtils.isNotEmpty(map)) { ... }

// Map为空
if (MapUtils.isEmpty(map)) { ... }
```

### 字符串判断
```java
// 字符串非空
if (StringUtils.isNotBlank(str)) { ... }

// 字符串为空
if (StringUtils.isBlank(str)) { ... }
```

### 其他工具
```java
// 对象转JSON
String json = JSON.toJSONString(obj);

// 单行创建集合
Set<String> set = Sets.newHashSet();
List<String> list = Lists.newArrayList();

// 添加监控
RequestUtil.reportUmp("metric_name");

// 检查开关
if (ConfigWareUtils.isOpen(ConfigKeys.XXX)) { ... }
```

## 触发关键词
- "重构java代码"