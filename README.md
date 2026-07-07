# shawn-skills

> 一套面向中文开发者的 Codex Agent Skills，覆盖 Linux 运维安装、Java 代码重构、性能分析和文档生成——让 AI 助手按团队规范干活。

[![GitHub stars](https://img.shields.io/github/stars/rurubudong1211/shawn-skills-main?style=flat)](https://github.com/rurubudong1211/shawn-skills-main)
[![License](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)
[![Skills](https://img.shields.io/badge/skills-4-blue)](./skills)

## ✨ 项目亮点

- **开箱即用的 AI 技能包**：每个 skill 自带触发条件、工作流程和参考资源，安装即用，无需额外配置。
- **面向中文开发场景**：默认中文交互，适配 Linux/WSL、Java 团队规范、中文文档生成等国内常见需求。
- **结构化可维护**：每个 skill 独立目录，规则、参考文档、脚本分离，方便团队定制和版本管理。

## 🎯 适合谁用

- 用 **Codex / Claude Code** 等 AI 编程助手，想让 AI 按团队约定执行特定任务。
- 需要标准化的 **Linux 软件安装流程**（Docker、Nginx、MySQL），减少运维摸索时间。
- 希望 AI 自动按规范 **重构 Java 代码**，统一卫语句、工具类和魔法值处理。
- 想让 AI 帮忙 **分析性能瓶颈** 或 **生成中文项目文档**。

## 📦 安装

### 方式一：Skill Installer（推荐）

在 Codex 中直接通过 `$skill-installer` 安装：

```text
使用 $skill-installer 从 GitHub 仓库 rurubudong1211/shawn-skills-main 安装：
skills/shawn-linux-installer
skills/shawn-java-refactor
skills/shawn-perf-profiler
skills/shawn-zh-readme
```

安装完成后 **重启 Codex** 即可加载新技能。

### 方式二：手动安装

将需要的 skill 目录复制到本地 Codex skills 目录：

**Windows：**
```text
%USERPROFILE%\.codex\skills\
```

**macOS / Linux：**
```text
~/.codex/skills/
```

最终目录结构应类似：

```text
~/.codex/skills/shawn-linux-installer/SKILL.md
~/.codex/skills/shawn-java-refactor/SKILL.md
~/.codex/skills/shawn-perf-profiler/SKILL.md
~/.codex/skills/shawn-zh-readme/SKILL.md
```

## 🧭 Skills 一览

| Skill | 用途 | 触发场景 |
|-------|------|----------|
| `shawn-linux-installer` | Linux 软件安装运维 | 在 Linux/WSL 上安装 Docker、Nginx、MySQL；环境采集、方案选择、错误处理、生成安装总结 |
| `shawn-java-refactor` | Java 两步重构 | 卫语句降嵌套、替换约定工具类、减少不必要的 lambda、提取魔法值 |
| `shawn-perf-profiler` | 性能分析 | 代码级、数据库级、网络级瓶颈识别与优化建议 |
| `shawn-zh-readme` | 中文 README 生成 | 分析项目后生成面向中文开发者的高质量 README |

### 典型用法

```text
# 安装 MySQL 并生成中文安装记录
使用 $shawn-linux-installer 帮我在 Ubuntu 上安装 MySQL --type summary

# 按团队规范重构 Java 代码
使用 $shawn-java-refactor 重构这个 Java 文件

# 分析性能瓶颈
使用 $shawn-perf-profiler 分析这个接口的性能问题

# 为项目生成中文 README
帮这个仓库写一个中文 README
```

## 📁 项目结构

```text
shawn-skills-main/
├── skills/                          # 正式 skill（每个独立目录）
│   ├── shawn-linux-installer/       # Linux 安装运维
│   │   ├── SKILL.md                 # skill 主文件（触发条件、工作流程）
│   │   ├── agents/openai.yaml       # UI 展示信息
│   │   ├── references/              # 参考文档（安装手册）
│   │   └── scripts/                 # 辅助脚本（环境采集）
│   ├── shawn-java-refactor/         # Java 两步重构
│   │   ├── SKILL.md
│   │   ├── agents/openai.yaml
│   │   └── references/              # 重构模式参考
│   ├── shawn-perf-profiler/         # 性能分析
│   │   └── SKILL.md
│   └── shawn-zh-readme/             # 中文 README 生成器
│       └── SKILL.md
├── .agents/skills/                  # 本地 agent 技能（仅 shaown-zh-readme）
└── README.md
```

## 🛠️ 自定义开发

### Skill 结构规范

新建一个 skill 只需创建以下结构：

```text
skills/<skill-name>/
├── SKILL.md              # 必需：触发条件（frontmatter）+ 工作流程
├── agents/openai.yaml    # 可选：UI 展示信息
├── references/           # 可选：复杂规则、示例、参考资料
└── scripts/              # 可选：辅助脚本
```

### SKILL.md 模板

```markdown
---
name: your-skill-name
description: 一句话描述，包含触发关键词（Use when ...）
---

# Skill 标题

## 触发条件
...

## 工作流程
...
```

- 正式 skill 放在 `skills/<name>/SKILL.md`
- frontmatter 只保留 `name` 和 `description`
- 复杂规则放入 `references/`，在 `SKILL.md` 中说明何时读取
- UI 展示信息写入 `agents/openai.yaml`

## 🤝 贡献

欢迎 PR / Issue。贡献流程：

1. Fork 本仓库
2. 在 `skills/` 下新建或修改 skill 目录
3. 确保 `SKILL.md` 的 frontmatter 格式正确
4. 提交 PR 并附上 skill 的使用说明

## 📝 License

MIT © 2026 — 详见 [LICENSE](./LICENSE)

---

> **仓库地址**：[github.com/rurubudong1211/shawn-skills-main](https://github.com/rurubudong1211/shawn-skills-main)
