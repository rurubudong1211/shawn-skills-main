# shawn-skills-main

这是一个 Skills 仓库，用于沉淀可复用的工作流和专项能力。

当前项目主要包含两个正式 skills：

- `shawn-linux-installer`
- `shawn-java-refactor`

`skills/shawn-test` 是测试用 skill，不作为项目能力记录在本 README 中。

## 目录结构

```text
skills/
├── shawn-linux-installer/
│   ├── SKILL.md
│   ├── agents/
│   ├── references/
│   └── scripts/
├── shawn-java-refactor/
│   ├── SKILL.md
│   └── REFERENCE.md
└── shawn-test/          # 测试用，不纳入正式说明
```

## Skills

### shawn-linux-installer

Linux 软件安装指导 skill，主要用于中文环境下的服务器软件安装、部署、验证和故障排查。

适用场景：

- Docker / Docker Compose 安装与验证
- Nginx 安装、容器化部署与端口验证
- MySQL 安装、Docker Compose 部署与初始化检查
- Linux / WSL 环境信息采集
- 根据发行版、包管理器、init 系统和网络条件选择安装方案
- 按步骤提供命令、验证方式、预期结果和失败排查方向

该 skill 默认以交互式运维流程工作：先采集环境，再选择安装方案，之后按小步骤执行并验证。

当用户请求中包含 `--type summary` 时，该 skill 会生成中文 Markdown 安装记录，保存到：

```text
.shawn-skills/shawn-linux-installer/
```

### shawn-java-refactor

Java 代码两步重构 skill，用于按照团队约定提升代码可读性、健壮性，并处理魔法值。

重构流程：

1. 提升代码健壮性和可读性。
2. 将魔法数字、魔法字符串提取为类内常量。

主要规则：

- 优先使用卫语句减少嵌套。
- 尽量减少 lambda 表达式，必要时改为常规循环或条件逻辑。
- 尽量不创建新方法；确需创建时控制子方法数量。
- 使用约定工具类进行空值、集合、字符串判断。
- 将硬编码数字和字符串提取为 `private static final` 常量。

常用工具类约定：

- `Objects.isNull` / `Objects.nonNull`
- `CollectionUtils.isEmpty` / `CollectionUtils.isNotEmpty`
- `MapUtils.isEmpty` / `MapUtils.isNotEmpty`
- `StringUtils.isBlank` / `StringUtils.isNotBlank`
- `JSON.toJSONString`
- `Sets.newHashSet` / `Lists.newArrayList`
- `RequestUtil.reportUmp`
- `ConfigWareUtils.isOpen`

## 使用方式

将本仓库中的 `skills` 目录配置到 Codex 可读取的 skills 路径后，即可在对话中通过对应 skill 名称或触发描述使用。

示例：

```text
使用 shawn-linux-installer 帮我安装 Docker
```

```text
使用 shawn-java-refactor 重构这个 Java 文件
```

## 维护说明

- 正式 skill 放在 `skills/<skill-name>/SKILL.md`。
- 复杂规则、示例和参考资料可放在对应 skill 的 `references` 或独立参考文件中。
- 测试 skill 可以保留在 `skills/shawn-test`，但不要写入正式项目说明。
