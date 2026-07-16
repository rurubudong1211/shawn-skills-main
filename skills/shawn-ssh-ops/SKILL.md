---
name: shawn-ssh-ops
description: 通过 SSH 连接 Linux 服务器，使用自然语言查询服务器运行状态（磁盘、内存、CPU、进程等）。仅通过显式 /shawn-ssh-ops 触发。
---

# SSH 运维助手 (shawn-ssh-ops)

通过 SSH 免密连接 Linux 服务器，接收用户的自然语言描述，自动翻译为 shell 命令并执行，返回结果。

## 全局配置

| 配置项 | 路径 |
|--------|------|
| SSH 密钥 | `~/.ssh/id_ed25519_skill` |
| 服务器别名配置 | `~/.linux-server-monitor/servers.json` |

### servers.json 格式

```json
{
  "web-118": {
    "host": "192.168.1.118",
    "port": 22,
    "user": "root"
  }
}
```

## 工作流程

用户输入可能是以下几种操作之一，根据语义判断。**初始化（密钥和配置文件）仅在「添加服务器」操作时按需触发，其他操作不做初始化。**

#### A. 查询服务器状态

用户自然语言描述查询意图，例如：
- "帮我查看 web-118 服务器的磁盘使用情况"
- "web-118 的内存还剩多少"
- "看看 web-118 的 CPU 负载"

**前置检查（不做初始化）：**
- 如果 `servers.json` 不存在或为空 → 提示："⚠️ 当前没有配置任何服务器，请先使用「添加服务器」配置一台。"
- 如果 `~/.ssh/id_ed25519_skill` 不存在 → 提示："⚠️ SSH 密钥尚未生成，请先使用「添加服务器」配置一台（添加时会自动生成密钥）。"

**处理流程：**

1. **识别别名**：从用户输入中提取服务器别名，在 `servers.json` 中查找
   - 如果用户未指定别名且只有一台服务器，自动使用它
   - 如果用户未指定别名且有多台服务器，列出所有别名让用户选择
   - 如果别名在 `servers.json` 中不存在，提示用户先添加

2. **翻译为 shell 命令**：将用户的自然语言查询翻译为 Linux shell 命令
   - 可以翻译任意命令，不设限制
   - 对于持续输出型命令（如 `top`、`tail -f`），自动添加终止条件：
     - `top` → `top -bn1 | head -20`
     - `tail -f` → `tail -n 100`
     - `ping` → `ping -c 4`
     - `vmstat` → `vmstat 1 3`
   - 多个独立查询合并为一条命令，用 `&& echo "---" &&` 串联

3. **展示即将执行的命令**（不等待确认）

4. **执行命令**：
   ```bash
   ssh -i ~/.ssh/id_ed25519_skill -p {port} -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 {user}@{host} "{command}"
   ```
   - 命令执行兜底超时 60 秒：用 `timeout 60 ssh ...` 包裹
   - 如果命令本身可能超时，在远程命令中也加 `timeout`

5. **展示结果**：
   ```
   🔗 {别名} ({host}:{port})   ⏱ {耗时}s
   $ {执行的命令}
   {原始输出}
   ```

#### B. 列出所有服务器

用户输入："列出所有服务器" / "有哪些服务器" / "服务器列表"

**注意：此操作不做任何初始化，不生成密钥或配置文件。**

直接尝试读取 `servers.json`：
- 如果文件不存在或内容为空 `{}`，直接提示："📋 当前没有配置任何服务器。你可以说「添加服务器」来配置第一台。"
- 如果存在且有内容，展示：
```
📋 已配置的服务器别名：
  🔹 web-118 → root@192.168.1.118:22
  🔹 db-01 → root@10.0.0.5:22
```

#### C. 添加服务器

用户输入："添加服务器" / "添加别名 web-118" / "新增一台服务器"

**此操作是唯一触发初始化的入口。**

**处理流程：**

1. **收集信息**：引导用户依次提供：
   - 别名（如 `web-118`）
   - IP 地址或主机名
   - SSH 端口（默认 22）
   - 用户名（默认 root）

2. **检查并初始化环境**（仅在此时按需执行）：
   - 如果 `~/.ssh/id_ed25519_skill` 不存在 → 生成密钥（见下方初始化流程）
   - 如果 `~/.linux-server-monitor/servers.json` 不存在 → 创建目录和空 JSON `{}`

3. **复制公钥到服务器**：
   执行命令（利用 SSH 交互式密码提示）：
   ```bash
   type ~/.ssh/id_ed25519_skill.pub | ssh -p {port} -o StrictHostKeyChecking=accept-new {user}@{host} "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   ```
   - 用户需要在终端中输入一次密码
   - 提示用户："请在终端中输入 {user}@{host} 的密码："

4. **测试免密登录**：
   ```bash
   ssh -i ~/.ssh/id_ed25519_skill -p {port} -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new {user}@{host} "echo OK"
   ```
   - 如果返回 "OK"或其他成功输出，表示配置成功

5. **写入配置**：将别名信息写入 `servers.json`

6. **报告结果**：
   ```
   ✅ 服务器 web-118 已配置，免密登录已建立
     别名: web-118
     连接: root@192.168.1.118:22
   ```

#### D. 删除服务器

用户输入："删除 web-118" / "移除服务器 web-118"

**前置检查（不做初始化）：**
- 如果 `servers.json` 不存在或为空 → 提示："⚠️ 当前没有配置任何服务器，无需删除。"

1. 确认别名存在于 `servers.json`
   - 如果不存在 → 提示："⚠️ 别名 `{alias}` 不存在于服务器列表中。"
2. 从 JSON 中删除该记录
3. 报告："✅ 服务器 web-118 已删除"

**注意：** 只删除本地配置，不移除服务器上的公钥。

---

### 初始化流程（仅「添加服务器」时按需触发）

以下步骤仅在执行「添加服务器」操作且对应资源缺失时执行：

#### 密钥不存在

1. 生成 SSH 密钥：
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_skill -N "" -C "ssh-ops-skill"
   ```
2. 告知用户密钥已生成

#### 配置文件不存在

1. 创建配置目录和文件：
   ```bash
   mkdir -p ~/.linux-server-monitor && echo "{}" > ~/.linux-server-monitor/servers.json
   ```

---

## 错误处理

执行过程中遇到错误时，识别错误类型并用中文给出友好提示：

| 错误模式 | 中文提示 |
|----------|----------|
| `Connection timed out` / `connect to host * port *: Operation timed out` | ⚠️ 连接超时：无法连接到服务器，请检查 IP 地址和端口是否正确，以及服务器是否在线。 |
| `Connection refused` | ⚠️ 连接被拒绝：服务器拒绝了连接，请检查 SSH 服务是否运行，以及端口号是否正确。 |
| `Permission denied (publickey)` | ⚠️ 密钥认证失败：免密登录可能失效，请尝试重新添加该服务器以更新公钥。 |
| `Host key verification failed` | ⚠️ 主机密钥不匹配：服务器指纹已变更，请从 `~/.ssh/known_hosts` 中删除对应条目后重试。 |
| `No such file or directory` | ⚠️ 找不到文件或目录。 |
| `Name or service not known` / `Could not resolve hostname` | ⚠️ 无法解析主机名：请检查 IP 地址是否正确。 |

对于未匹配到的错误，将原始 stderr 原样展示，同时附上错误提示。

---

## 注意事项

1. **按需初始化**：密钥和配置文件仅在「添加服务器」时按需生成；其他操作（列出、查询、删除）如遇资源缺失，直接提示用户先添加服务器，不做自动初始化。
2. **命令展示但不等确认**：执行前展示命令，但直接执行不等待用户确认
3. **无命令限制**：不做安全白名单，LLM 自由翻译自然语言为任意命令
4. **单次一个别名**：不支持同时查询多台服务器
5. **仅显式触发**：用户必须以 `/shawn-ssh-ops` 开头才会激活此 skill
6. **Windows 兼容**：使用 `type` 命令替代 `cat` 读取公钥文件，在 Windows 上也能执行
