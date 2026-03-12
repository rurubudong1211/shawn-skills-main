# Java两步重构参考指南

## 第一步重构详细规则

### 1. 卫语句（Guard Clauses）重构

#### 重构前
```java
public void processOrder(Order order) {
    if (order != null) {
        if (order.getItems() != null) {
            if (order.getItems().size() > 0) {
                // 处理订单逻辑
                for (Item item : order.getItems()) {
                    processItem(item);
                }
            } else {
                log.error("订单项为空");
            }
        } else {
            log.error("订单项为null");
        }
    } else {
        log.error("订单为null");
    }
}
```

#### 重构后
```java
public void processOrder(Order order) {
    if (Objects.isNull(order)) {
        log.error("订单为null");
        return;
    }
    if (CollectionUtils.isEmpty(order.getItems())) {
        log.error("订单项为空");
        return;
    }
    // 处理订单逻辑
    for (Item item : order.getItems()) {
        processItem(item);
    }
}
```

### 2. Lambda表达式替换

#### 重构前
```java
List<String> names = users.stream()
    .filter(u -> u.getAge() > 18)
    .map(u -> u.getName())
    .collect(Collectors.toList());
```

#### 重构后
```java
List<String> names = Lists.newArrayList();
for (User user : users) {
    if (user.getAge() > 18) {
        names.add(user.getName());
    }
}
```

### 3. 工具类使用示例

#### 空值判断
```java
// 原始代码
if (user != null && user.getProfile() != null) {
    String email = user.getProfile().getEmail();
    if (email != null && !email.trim().isEmpty()) {
        sendEmail(email);
    }
}

// 重构后
if (Objects.nonNull(user) && Objects.nonNull(user.getProfile())) {
    String email = user.getProfile().getEmail();
    if (StringUtils.isNotBlank(email)) {
        sendEmail(email);
    }
}
```

#### JSON转换
```java
// 重构前
String json = "{\"id\":" + user.getId() + ",\"name\":\"" + user.getName() + "\"}";

// 重构后
String json = JSON.toJSONString(user);
```

#### 集合创建
```java
// 重构前
Set<String> cacheKeys = new HashSet<>();
cacheKeys.add("key1");
cacheKeys.add("key2");

// 重构后
Set<String> cacheKeys = Sets.newHashSet("key1", "key2");
```

### 4. 监控和开关使用

```java
public void processPayment(PaymentRequest request) {
    // 检查开关
    if (!ConfigWareUtils.isOpen(ConfigKeys.PAYMENT_PROCESS_ENABLED)) {
        log.warn("支付处理功能已关闭");
        return;
    }

    try {
        // 处理支付逻辑
        doProcessPayment(request);

        // 上报监控
        RequestUtil.reportUmp("payment_success");
    } catch (Exception e) {
        log.error("支付处理失败", e);
        RequestUtil.reportUmp("payment_error");
        throw new PaymentException("支付处理失败", e);
    }
}
```

## 第二步重构详细规则

### 魔法值提取

#### 重构前
```java
public class OrderService {
    public double calculateDiscount(Order order) {
        if (order.getTotalAmount() > 1000) {
            return order.getTotalAmount() * 0.1;  // 1000和0.1是魔法值
        } else if (order.getTotalAmount() > 500) {
            return order.getTotalAmount() * 0.05;  // 500和0.05是魔法值
        }
        return 0;
    }

    public void sendNotification(Order order) {
        String content = "您的订单" + order.getId() + "已确认，预计2个工作日内发货";
        // "2个工作日内"是魔法值
        emailService.send(order.getEmail(), "订单确认", content);
    }
}
```

#### 重构后
```java
public class OrderService {
    private static final double VIP_DISCOUNT_THRESHOLD = 1000.0;
    private static final double VIP_DISCOUNT_RATE = 0.1;
    private static final double REGULAR_DISCOUNT_THRESHOLD = 500.0;
    private static final double REGULAR_DISCOUNT_RATE = 0.05;
    private static final String DEFAULT_SHIPPING_TIME = "2个工作日内";
    private static final String ORDER_CONFIRMATION_SUBJECT = "订单确认";

    public double calculateDiscount(Order order) {
        double totalAmount = order.getTotalAmount();
        if (totalAmount > VIP_DISCOUNT_THRESHOLD) {
            return totalAmount * VIP_DISCOUNT_RATE;
        } else if (totalAmount > REGULAR_DISCOUNT_THRESHOLD) {
            return totalAmount * REGULAR_DISCOUNT_RATE;
        }
        return 0;
    }

    public void sendNotification(Order order) {
        String content = "您的订单" + order.getId() + "已确认，预计" + DEFAULT_SHIPPING_TIME + "发货";
        emailService.send(order.getEmail(), ORDER_CONFIRMATION_SUBJECT, content);
    }
}
```

## 重构检查清单

### 第一步检查项
- [ ] 所有嵌套if-else都已转换为卫语句
- [ ] 使用了指定的工具类进行空值和集合判断
- [ ] lambda表达式已替换为常规代码（除非必要）
- [ ] 代码结构清晰，方法不超过3个
- [ ] 添加了必要的监控和开关检查

### 第二步检查项
- [ ] 识别所有魔法值（数字、字符串字面量）
- [ ] 为每个魔法值创建有意义的常量名
- [ ] 常量已正确替换所有引用位置
- [ ] 常量命名符合规范（全大写，下划线分隔）

## 常见重构模式

### 1. 复杂条件逻辑重构
```java
// 重构前
public boolean canProcess(Order order, User user) {
    if (order != null) {
        if (order.getStatus() == OrderStatus.PENDING) {
            if (user != null) {
                if (user.hasPermission("PROCESS_ORDER")) {
                    return true;
                }
            }
        }
    }
    return false;
}

// 重构后
public boolean canProcess(Order order, User user) {
    if (Objects.isNull(order)) {
        return false;
    }
    if (order.getStatus() != OrderStatus.PENDING) {
        return false;
    }
    if (Objects.isNull(user)) {
        return false;
    }
    return user.hasPermission("PROCESS_ORDER");
}
```

### 2. 循环优化
```java
// 重构前
List<String> results = new ArrayList<>();
for (int i = 0; i < list.size(); i++) {
    String item = list.get(i);
    if (item != null && item.startsWith("prefix")) {
        results.add(item.toUpperCase());
    }
}

// 重构后
List<String> results = Lists.newArrayList();
for (String item : list) {
    if (StringUtils.isBlank(item)) {
        continue;
    }
    if (!item.startsWith("prefix")) {
        continue;
    }
    results.add(item.toUpperCase());
}
```