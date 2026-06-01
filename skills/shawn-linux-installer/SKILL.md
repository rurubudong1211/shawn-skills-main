---
name: shawn-linux-installer
description: Guides Chinese-language Linux software installation support for Docker/doker, Docker Compose, Nginx, MySQL, and common server packages. Use when users ask how to install, deploy, verify, or troubleshoot software on Linux hosts or inside Docker containers, especially when environment discovery, package-manager selection, step-by-step commands, validation, and error recovery are needed.
---

# Linux Software Installer

Guide users through Linux software installation as an interactive operations workflow. Default to Chinese explanations, keep command names and package names in English, and assume Codex cannot directly log in to the user's server unless the user says otherwise.

## Core Workflow

1. **Collect environment first.** If the user has not already provided enough host details, read `scripts/collect_linux_env.sh` and give the user a copy-paste command to run it on the Linux host. Ask them to paste the full output back.
2. **Identify missing decisions.** Confirm only the details that change the plan: install target, production vs test, root/sudo availability, public internet access, official repository vs distribution repository, mirror requirements, data persistence, exposed ports, and existing services using the same ports.
3. **Offer multiple plans.** Present at least two viable options before commands, usually:
   - Official upstream repository: best for newer Docker/Nginx/MySQL versions and normal upgrades.
   - Distribution package repository: simpler and often safer for conservative servers, but versions may lag.
   - Docker Compose deployment: preferred for Nginx/MySQL inside Docker when persistence and repeatability matter.
4. **Execute one step at a time.** After the user chooses a plan, provide one small step at a time. Each step must include: purpose, commands, verification command, expected success signal, and what error output to send back if it fails.
5. **Troubleshoot before continuing.** If a command fails, diagnose from the exact error text, propose the smallest fix, verify the fix, then continue the chosen plan. Do not skip failed verification.

## Environment Collection

When collecting host details, ask the user to run the bundled script on their Linux host. Prefer a here-doc so the user does not need to download anything:

```bash
cat > /tmp/collect_linux_env.sh <<'EOF'
# Paste the contents of scripts/collect_linux_env.sh here.
EOF
sh /tmp/collect_linux_env.sh
```

If the user cannot run scripts, ask for these commands instead:

```bash
cat /etc/os-release
uname -a
id
free -h
df -hT /
command -v apt-get dnf yum zypper apk docker podman systemctl sudo
ss -ltnp 2>/dev/null || netstat -ltnp 2>/dev/null
```

Treat the collection script as read-only. Do not ask the user to run install commands until the environment and target are clear.

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

- Read `scripts/collect_linux_env.sh` whenever environment collection is needed.
- Read `references/install-playbooks.md` after the target software and Linux family are known, then adapt the relevant playbook to the user's collected environment.
- For exact production repository commands, verify against official vendor documentation when browsing is available, because supported versions and repository setup can change.
