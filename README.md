# shawn-skills-main

这是一个 Codex Skills 仓库，用于沉淀可复用的工作流和专项能力。

当前项目包含两个正式 skills：

- `shawn-linux-installer`
- `shawn-java-refactor`

## 目录结构

```text
skills/
├── shawn-linux-installer/
│   ├── SKILL.md
│   ├── agents/
│   │   └── openai.yaml
│   ├── references/
│   └── scripts/
└── shawn-java-refactor/
    ├── SKILL.md
    ├── agents/
    │   └── openai.yaml
    └── references/
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

## 安装

将本仓库推送到 GitHub 后，别人可以在 Codex 中使用 `$skill-installer` 安装指定 skill。

安装单个 skill：

```text
使用 $skill-installer 从 https://github.com/<owner>/shawn-skills-main/tree/main/skills/shawn-linux-installer 安装
```

```text
使用 $skill-installer 从 https://github.com/<owner>/shawn-skills-main/tree/main/skills/shawn-java-refactor 安装
```

一次安装多个 skills：

```text
使用 $skill-installer 从 GitHub 仓库 <owner>/shawn-skills-main 安装：
skills/shawn-linux-installer
skills/shawn-java-refactor
```

安装完成后，需要重启 Codex 才会加载新 skills。

## 手动安装

也可以 clone 本仓库后，将需要的 skill 目录复制到本机 Codex skills 目录。

Windows：

```text
%USERPROFILE%\.codex\skills\
```

macOS / Linux：

```text
~/.codex/skills/
```

最终目录应类似：

```text
~/.codex/skills/shawn-linux-installer/SKILL.md
~/.codex/skills/shawn-java-refactor/SKILL.md
```

## 维护说明

- 正式 skill 放在 `skills/<skill-name>/SKILL.md`。
- `SKILL.md` frontmatter 只保留 `name` 和 `description`，避免放入无效字段。
- 复杂规则、示例和参考资料放在对应 skill 的 `references/` 目录中，并从 `SKILL.md` 说明何时读取。
- UI 展示信息放在 `agents/openai.yaml`，包括 `display_name`、`short_description` 和 `default_prompt`。
