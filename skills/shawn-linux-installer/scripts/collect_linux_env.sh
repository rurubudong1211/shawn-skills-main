#!/bin/sh
# Read-only Linux environment collection for installation planning.

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

section() {
  printf '\n## %s\n' "$1"
}

kv() {
  printf '%-24s %s\n' "$1:" "$2"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

cmd_path() {
  if have "$1"; then
    command -v "$1"
  else
    printf 'not found'
  fi
}

run_capture() {
  label="$1"
  shift
  printf '\n### %s\n' "$label"
  "$@" 2>&1
  status=$?
  if [ "$status" -ne 0 ]; then
    printf '(command exited with status %s)\n' "$status"
  fi
}

first_os_value() {
  key="$1"
  if [ -r /etc/os-release ]; then
    value=$(sed -n "s/^${key}=//p" /etc/os-release | head -n 1 | sed 's/^"//; s/"$//')
    if [ -n "$value" ]; then
      printf '%s' "$value"
    else
      printf 'unknown'
    fi
  else
    printf 'unknown'
  fi
}

printf 'BEGIN linux-software-installer environment report\n'
kv "collected_at_utc" "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || printf 'unknown')"
kv "hostname" "$(hostname 2>/dev/null || printf 'unknown')"
kv "user" "$(id 2>/dev/null || printf 'unknown')"

section "OS"
kv "pretty_name" "$(first_os_value PRETTY_NAME)"
kv "id" "$(first_os_value ID)"
kv "version_id" "$(first_os_value VERSION_ID)"
kv "version_codename" "$(first_os_value VERSION_CODENAME)"
kv "kernel" "$(uname -r 2>/dev/null || printf 'unknown')"
kv "machine" "$(uname -m 2>/dev/null || printf 'unknown')"
if have systemd-detect-virt; then
  kv "virtualization" "$(systemd-detect-virt 2>/dev/null || printf 'none/unknown')"
else
  kv "virtualization" "unknown"
fi

section "CPU and Memory"
if have getconf; then
  kv "cpu_online" "$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf 'unknown')"
else
  kv "cpu_online" "unknown"
fi
if [ -r /proc/cpuinfo ]; then
  kv "cpu_model" "$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -n 1)"
else
  kv "cpu_model" "unknown"
fi
if have free; then
  run_capture "free -h" free -h
elif [ -r /proc/meminfo ]; then
  run_capture "/proc/meminfo summary" awk '/MemTotal|MemAvailable|SwapTotal|SwapFree/ {print}' /proc/meminfo
else
  kv "memory" "unknown"
fi

section "Disk"
if have df; then
  run_capture "df -hT for key paths" df -hT / /var /tmp /var/lib/docker
else
  kv "df" "not found"
fi
if have lsblk; then
  run_capture "lsblk" lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
else
  kv "lsblk" "not found"
fi

section "Package Managers"
for tool in apt-get apt dnf yum microdnf zypper apk pacman rpm dpkg snap; do
  kv "$tool" "$(cmd_path "$tool")"
done

section "Privileges and Init"
kv "sudo" "$(cmd_path sudo)"
if have groups; then
  kv "groups" "$(groups 2>/dev/null || printf 'unknown')"
fi
if have ps; then
  kv "pid1" "$(ps -p 1 -o comm= 2>/dev/null | sed 's/^[[:space:]]*//')"
else
  kv "pid1" "unknown"
fi
kv "systemctl" "$(cmd_path systemctl)"
if have systemctl; then
  kv "systemd_state" "$(systemctl is-system-running 2>/dev/null || printf 'unknown')"
fi

section "Network"
if have ip; then
  run_capture "ip -brief addr" ip -brief addr
else
  kv "ip" "not found"
fi
for host in download.docker.com registry-1.docker.io auth.docker.io nginx.org repo.mysql.com; do
  if have getent; then
    resolved=$(getent hosts "$host" 2>/dev/null | head -n 1)
    if [ -n "$resolved" ]; then
      kv "resolve $host" "$resolved"
    else
      kv "resolve $host" "failed"
    fi
  elif have nslookup; then
    printf '\n### resolve %s\n' "$host"
    nslookup "$host" 2>&1 | sed -n '1,12p'
  else
    kv "resolve $host" "no getent/nslookup"
  fi
done
if have curl; then
  for url in https://download.docker.com https://registry-1.docker.io/v2/ https://nginx.org https://repo.mysql.com; do
    printf '\n### curl %s\n' "$url"
    curl -I -L --connect-timeout 5 --max-time 10 -sS -o /dev/null -w 'http_code=%{http_code} remote_ip=%{remote_ip} total_time=%{time_total}\n' "$url" 2>&1
  done
elif have wget; then
  for url in https://download.docker.com https://registry-1.docker.io/v2/ https://nginx.org https://repo.mysql.com; do
    printf '\n### wget --spider %s\n' "$url"
    wget --spider --timeout=10 "$url" 2>&1 | sed -n '1,20p'
  done
else
  kv "http_client" "curl/wget not found"
fi

section "Container Runtime"
for tool in docker podman containerd ctr runc docker-compose; do
  kv "$tool" "$(cmd_path "$tool")"
done
if have docker; then
  run_capture "docker --version" docker --version
  run_capture "docker compose version" docker compose version
  if have timeout; then
    run_capture "docker info (5s timeout)" timeout 5 docker info
  else
    kv "docker info" "skipped: timeout command not found"
  fi
fi
if have podman; then
  run_capture "podman --version" podman --version
  if have timeout; then
    run_capture "podman info (5s timeout)" timeout 5 podman info
  else
    kv "podman info" "skipped: timeout command not found"
  fi
fi

section "Firewall and SELinux"
for tool in firewall-cmd ufw iptables nft getenforce sestatus; do
  kv "$tool" "$(cmd_path "$tool")"
done
if have firewall-cmd; then
  run_capture "firewall-cmd --state" firewall-cmd --state
  run_capture "firewall-cmd --list-all" firewall-cmd --list-all
fi
if have ufw; then
  run_capture "ufw status verbose" ufw status verbose
fi
if have getenforce; then
  run_capture "getenforce" getenforce
fi

section "Listening Ports"
if have ss; then
  printf '\n### ss -ltnp filtered for 80/443/3306/33060\n'
  ss -ltnp 2>/dev/null | awk 'NR==1 || $0 ~ /:80([[:space:]]|$)|:443([[:space:]]|$)|:3306([[:space:]]|$)|:33060([[:space:]]|$)/'
elif have netstat; then
  printf '\n### netstat -ltnp filtered for 80/443/3306/33060\n'
  netstat -ltnp 2>/dev/null | awk 'NR==1 || $0 ~ /:80([[:space:]]|$)|:443([[:space:]]|$)|:3306([[:space:]]|$)|:33060([[:space:]]|$)/'
else
  kv "ports" "ss/netstat not found"
fi

section "Service Status"
if have systemctl; then
  for svc in docker containerd podman nginx mysqld mysql firewalld; do
    printf '\n### systemctl status %s\n' "$svc"
    enabled=$(systemctl is-enabled "$svc" 2>/dev/null || printf 'unknown')
    active=$(systemctl is-active "$svc" 2>/dev/null || printf 'unknown')
    printf 'enabled: %s\n' "$enabled"
    printf 'active: %s\n' "$active"
  done
else
  kv "systemctl services" "skipped"
fi

printf '\nEND linux-software-installer environment report\n'
