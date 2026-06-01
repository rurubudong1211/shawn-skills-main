---
name: shawn-linux-installer
description: Guides Chinese-language Linux software installation support for Docker, Docker Compose, Nginx, MySQL, and common server packages. Use when users ask how to install, deploy, verify, troubleshoot, or summarize software installation steps on Linux hosts, WSL, or Docker containers, especially when command-based environment discovery, package-manager selection, step-by-step commands, validation, error recovery, or the --type summary parameter is needed.
---

# Linux Software Installer

Guide users through Linux software installation as an interactive operations workflow. Default to Chinese explanations, keep command names and package names in English, and assume Codex cannot directly log in to the user's server unless the user says otherwise.

## Mode Selection

- Use the default interactive installation workflow unless the user includes `--type summary`.
- If the user includes `--type summary`, create a Chinese Markdown installation summary document instead of continuing normal step-by-step coaching.
- Treat `--type summary` as a request to summarize the user's installation process from the available conversation and environment details. If key facts are missing, still create the document and mark those fields as `unknown` or `not provided`; ask follow-up questions only when the missing detail would make the document misleading.

## Summary Mode

When `--type summary` is present, save a Markdown file under `.shawn-skills/shawn-linux-installer/` relative to the current workspace or current working directory.

Use this filename pattern:

```text
YYYYMMDD-HHMM-<target>-install-summary.md
```

Rules:

- Create the directory if it does not exist.
- Use a lowercase ASCII slug for `<target>`, such as `docker`, `nginx`, `mysql`, `docker-nginx`, or `linux-software`.
- Write the Markdown document in Chinese. Keep shell commands, package names, image names, service names, paths, and error messages in their original form.
- Include actual commands, verification commands, success/failure results, important environment facts, chosen plan, unresolved risks, and next steps.
- If the user only wants a planned installation document, label the status as `计划中`; if the user has already executed steps, label each step as `已完成`, `失败`, `待执行`, or `未知` based on the conversation.
- After saving, reply in Chinese with the absolute or workspace-relative path and a short summary of what was written.

Use this document structure:

````markdown
# <软件名称> 安装记录

- Skill: shawn-linux-installer
- 状态: 计划中 | 进行中 | 已完成 | 失败
- 创建时间: <本地时间>
- 目标主机: <hostname/ip 或 未提供>
- 系统版本: <发行版/版本 或 未提供>
- 安装目标: <Docker/Nginx/MySQL 等>
- 选择方案: <官方仓库/系统仓库/Docker Compose 等>

## 环境信息

<总结已采集的 Linux/WSL 环境信息。>

## 安装步骤

1. <步骤标题>
   - 目的: <说明为什么执行这一步>
   - 执行命令:
     ```bash
     <commands>
     ```
   - 验证命令:
     ```bash
     <verification commands>
     ```
   - 结果: 已完成 | 失败 | 待执行 | 未知

## 错误与修复

<列出出现过的错误、原因判断、修复动作和验证结果。没有错误时写“未记录错误”。>

## 最终验证

<最终健康检查命令和预期输出。>

## 后续建议

<防火墙、数据备份、重启策略、监控、凭据轮换等后续运维建议。>
````

## Core Workflow

1. **Collect environment first.** If the user has not already provided enough host details, give the user direct diagnostic commands to run on the target Linux/WSL host. Ask them to paste the full output back.
2. **Identify missing decisions.** Confirm only the details that change the plan: install target, production vs test, root/sudo availability, public internet access, official repository vs distribution repository, mirror requirements, data persistence, exposed ports, and existing services using the same ports.
3. **Offer multiple plans.** Present at least two viable options before commands, usually:
   - Official upstream repository: best for newer Docker/Nginx/MySQL versions and normal upgrades.
   - Distribution package repository: simpler and often safer for conservative servers, but versions may lag.
   - Docker Compose deployment: preferred for Nginx/MySQL inside Docker when persistence and repeatability matter.
4. **Execute one step at a time.** After the user chooses a plan, provide one small step at a time. Each step must include: purpose, commands, verification command, expected success signal, and what error output to send back if it fails.
5. **Troubleshoot before continuing.** If a command fails, diagnose from the exact error text, propose the smallest fix, verify the fix, then continue the chosen plan. Do not skip failed verification.

## Environment Collection

When collecting host details, ask the user to run direct diagnostic commands on the target Linux/WSL host. Do not collect by reading this skill's bundled script from a Windows path.

### PowerShell + WSL

If the user is in Windows PowerShell and wants to inspect WSL, first ask them to enter the WSL Linux shell:

```powershell
wsl.exe
```

Then ask them to run the Linux command block below inside WSL. If they are already stuck at a `>` or `>>` continuation prompt, tell them to press `Ctrl+C` once before continuing.

### Linux Command Collection

Use this command block for WSL and normal Linux shells:

```bash
printf '\n## OS\n'
cat /etc/os-release
uname -a

printf '\n## User and privileges\n'
id
command -v sudo || true

printf '\n## CPU and memory\n'
(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || true)
free -h

printf '\n## Disk\n'
df -hT /
df -hT /var /tmp /var/lib/docker 2>/dev/null || true

printf '\n## Package managers and init\n'
command -v apt-get apt dnf yum microdnf zypper apk pacman rpm dpkg systemctl || true
ps -p 1 -o comm= 2>/dev/null || true
systemctl is-system-running 2>/dev/null || true

printf '\n## Container runtimes\n'
command -v docker podman containerd ctr runc docker-compose || true
docker --version 2>/dev/null || true
docker compose version 2>/dev/null || true
docker info 2>/dev/null | sed -n '1,60p' || true

printf '\n## Network and DNS\n'
ip -brief addr 2>/dev/null || true
getent hosts download.docker.com registry-1.docker.io nginx.org repo.mysql.com 2>/dev/null || true

printf '\n## Firewall and SELinux\n'
command -v firewall-cmd ufw iptables nft getenforce sestatus || true
firewall-cmd --state 2>/dev/null || true
ufw status verbose 2>/dev/null || true
getenforce 2>/dev/null || true

printf '\n## Listening ports\n'
ss -ltnp 2>/dev/null || netstat -ltnp 2>/dev/null
```

Treat the diagnostic commands as read-only. Do not ask the user to run install commands until the environment and target are clear.

## Plan Selection Rules

- Prefer Docker official repositories for Docker Engine on supported Debian, Ubuntu, CentOS, Fedora, and RHEL hosts when the user wants current Docker packages.
- Prefer the distribution repository when the user wants minimum change, locked enterprise support, or no third-party repository.
- For Amazon Linux, prefer AWS-provided Docker packages unless the user explicitly wants upstream Docker packages and accepts compatibility tradeoffs.
- For Nginx on production hosts, prefer official nginx.org packages or the distribution repository; use Docker only when the user wants containerized deployment.
- For MySQL, prefer Docker Compose for quick isolated deployments; prefer vendor or distribution packages when the database must integrate with host-level backup, monitoring, and service management.
- For production data services, require explicit confirmation before destructive actions, changing existing ports, replacing packages, removing containers, or touching data directories.

## Step Format

For every execution step, respond in Chinese and include these five parts:

1. Step title and goal.
2. Commands to run in a fenced `bash` block.
3. Verification commands in a separate fenced `bash` block.
4. The expected success signal.
5. The exact output, log, or status command the user should send back if the step fails.

Keep commands copy-pasteable. Avoid combining unrelated changes into one step. Use `sudo` only when needed and explain if a command will open a firewall port, enable a service at boot, create a data directory, or expose a container port publicly.

## Troubleshooting Defaults

- DNS or repository errors: verify DNS, proxy, mirror, certificate time, and whether the repo supports the detected OS codename/version.
- Permission errors: verify `id`, sudo availability, Docker group membership, and whether the user needs a new login session after `usermod -aG docker`.
- Port conflicts: identify the listener with `ss -ltnp` or `lsof -i`, then choose a different host port or stop the conflicting service only after confirmation.
- `systemctl` unavailable: detect containers, WSL, or minimal init systems; use service-specific foreground checks or package scripts instead of systemd steps.
- Docker daemon errors: inspect `systemctl status docker`, `journalctl -u docker`, cgroup mode, storage driver, and `/var/lib/docker` disk space.
- MySQL container access errors: check first-start environment variables, existing named volumes, container logs, and whether the password was changed after initialization.

## Resources

- Use direct diagnostic command blocks for environment collection. Do not ask users to run `scripts/collect_linux_env.sh`; keep it only as an internal checklist for additional facts to collect.
- Read `references/install-playbooks.md` after the target software and Linux family are known, then adapt the relevant playbook to the user's collected environment.
- For exact production repository commands, verify against official vendor documentation when browsing is available, because supported versions and repository setup can change.
