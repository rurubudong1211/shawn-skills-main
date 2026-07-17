# Java 两步重构参考指南

## 卫语句

将深层嵌套的条件逻辑改为提前返回，优先让正常业务路径保持在较浅层级。

重构前：

```java
public void processOrder(Order order) {
    if (order != null) {
        if (CollectionUtils.isNotEmpty(order.getItems())) {
            for (Item item : order.getItems()) {
                processItem(item);
            }
        } else {
            log.error("订单项为空");
        }
    } else {
        log.error("订单为空");
    }
}
```

重构后：

```java
public void processOrder(Order order) {
    if (Objects.isNull(order)) {
        log.error("订单为空");
        return;
    }
    if (CollectionUtils.isEmpty(order.getItems())) {
        log.error("订单项为空");
        return;
    }

    for (Item item : order.getItems()) {
        processItem(item);
    }
}
```

## Lambda 和 stream

当 stream 链较长、调试困难、异常处理不清晰，或团队规范要求减少 lambda 时，改为常规循环。

重构前：

```java
List<String> names = users.stream()
        .filter(user -> user.getAge() > 18)
        .map(User::getName)
        .collect(Collectors.toList());
```

重构后：

```java
List<String> names = Lists.newArrayList();
for (User user : users) {
    if (user.getAge() <= 18) {
        continue;
    }
    names.add(user.getName());
}
```

## 工具类替换

优先替换项目中已有的原始空值、集合和字符串判断。

```java
if (Objects.nonNull(user) && Objects.nonNull(user.getProfile())) {
    String email = user.getProfile().getEmail();
    if (StringUtils.isNotBlank(email)) {
        sendEmail(email);
    }
}
```

常用替换：

- `obj != null` -> `Objects.nonNull(obj)`
- `obj == null` -> `Objects.isNull(obj)`
- `list != null && !list.isEmpty()` -> `CollectionUtils.isNotEmpty(list)`
- `list == null || list.isEmpty()` -> `CollectionUtils.isEmpty(list)`
- `map != null && !map.isEmpty()` -> `MapUtils.isNotEmpty(map)`
- `str != null && str.trim().length() > 0` -> `StringUtils.isNotBlank(str)`

## 魔法值提取

提取具有业务含义、重复出现或后续可能调整的字面量。

重构前：

```java
public double calculateDiscount(Order order) {
    if (order.getTotalAmount() > 1000) {
        return order.getTotalAmount() * 0.1;
    }
    if (order.getTotalAmount() > 500) {
        return order.getTotalAmount() * 0.05;
    }
    return 0;
}
```

重构后：

```java
private static final double VIP_DISCOUNT_THRESHOLD = 1000.0;
private static final double VIP_DISCOUNT_RATE = 0.1;
private static final double REGULAR_DISCOUNT_THRESHOLD = 500.0;
private static final double REGULAR_DISCOUNT_RATE = 0.05;

public double calculateDiscount(Order order) {
    double totalAmount = order.getTotalAmount();
    if (totalAmount > VIP_DISCOUNT_THRESHOLD) {
        return totalAmount * VIP_DISCOUNT_RATE;
    }
    if (totalAmount > REGULAR_DISCOUNT_THRESHOLD) {
        return totalAmount * REGULAR_DISCOUNT_RATE;
    }
    return 0;
}
```

## 检查清单

第一步重构检查：

- 深层嵌套是否能用卫语句降低层级。
- 空值、集合、字符串判断是否符合项目约定。
- stream/lambda 是否真的提升可读性；否则改为普通循环。
- 新增方法数量是否必要且受控。
- 日志、异常、监控、开关判断是否保持原顺序和原语义。

第二步重构检查：

- 魔法数字和魔法字符串是否具有业务含义。
- 常量名是否准确表达业务语义。
- 常量是否放在合适的类内位置。
- 所有引用是否已经替换。
- 没有机械提取无意义的 `0`、`1`、空字符串或一次性日志文本。
