# Install Playbooks

Use these playbooks after reading the environment report. Adapt commands to the detected distribution, architecture, init system, network access, and user choices. Verify current vendor docs before production repository setup when browsing is available.

Official references to check when exact package support matters:

- Docker Engine: https://docs.docker.com/engine/install/
- Docker Ubuntu: https://docs.docker.com/installation/ubuntulinux/
- Docker RHEL: https://docs.docker.com/engine/install/rhel/
- NGINX Linux packages: https://nginx.org/en/linux_packages.html
- NGINX Docker: https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/
- MySQL Linux install: https://dev.mysql.com/doc/refman/en/linux-installation.html
- MySQL Docker image: https://hub.docker.com/_/mysql

## Docker Engine

### Option A: official Docker repository

Use when the user wants current Docker Engine and the OS is supported by Docker.

Debian/Ubuntu family:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/<ubuntu-or-debian>/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/<ubuntu-or-debian> $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run --rm hello-world
```

RHEL:

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run --rm hello-world
```

CentOS/Rocky/Alma family:

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run --rm hello-world
```

Verification:

```bash
docker --version
docker compose version
sudo systemctl is-active docker
sudo docker run --rm hello-world
```

### Option B: distribution repository

Use when the user wants simple installation and accepts distro-maintained versions.

Debian/Ubuntu examples:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run --rm hello-world
```

RHEL-like examples vary by subscription and repositories. Check enabled repos first:

```bash
dnf repolist
dnf search docker
```

Amazon Linux 2023 commonly uses AWS packages:

```bash
sudo dnf update -y
sudo dnf install -y docker
sudo systemctl enable --now docker
sudo docker run --rm hello-world
```

Amazon Linux 2 commonly uses:

```bash
sudo amazon-linux-extras install -y docker
sudo systemctl enable --now docker
sudo docker run --rm hello-world
```

## Nginx

### Option A: host package

Distribution repository quick path:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y nginx
sudo systemctl enable --now nginx
curl -I http://127.0.0.1/

# RHEL-like
sudo dnf install -y nginx
sudo systemctl enable --now nginx
curl -I http://127.0.0.1/
```

Official nginx.org packages are preferred when the user needs upstream stable/mainline versions. Use the nginx.org Linux packages reference and verify the signing key fingerprint before installing.

### Option B: Docker container

Use a non-conflicting host port if 80 is already occupied:

```bash
sudo docker run -d --name nginx-test --restart unless-stopped -p 8080:80 nginx:stable
sudo docker ps --filter name=nginx-test
curl -I http://127.0.0.1:8080/
```

For persistent config/content, switch to Compose and bind named directories:

```yaml
services:
  nginx:
    image: nginx:stable
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - ./conf.d:/etc/nginx/conf.d:ro
```

## MySQL

### Option A: Docker Compose

Use for quick isolated deployments. Require the user to choose a strong password and confirm where data should persist.

```yaml
services:
  mysql:
    image: mysql:8.4
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: "change-this-password"
      MYSQL_DATABASE: "appdb"
      MYSQL_USER: "appuser"
      MYSQL_PASSWORD: "change-this-password-too"
    ports:
      - "127.0.0.1:3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql

volumes:
  mysql-data:
```

Verification:

```bash
docker compose up -d
docker compose ps
docker compose logs --tail=80 mysql
docker compose exec mysql mysql -uroot -p -e "SELECT VERSION();"
```

Warn the user that MySQL image initialization environment variables apply only when the data directory is empty. If a named volume already exists, changing `MYSQL_ROOT_PASSWORD` does not reset the root password.

### Option B: host package

Use when MySQL must be managed as a host service. Prefer the vendor repository for Oracle MySQL versions and distribution repositories for conservative OS-supported versions.

Ubuntu distribution example:

```bash
sudo apt-get update
sudo apt-get install -y mysql-server
sudo systemctl enable --now mysql
sudo systemctl status mysql --no-pager
sudo mysql -e "SELECT VERSION();"
```

RHEL-like systems may provide MySQL or MariaDB through AppStream. Confirm package identity before installing:

```bash
dnf module list mysql
dnf search mysql-server
```

## Common Error Handling

- `Unable to locate package docker-ce`: wrong OS codename, missing repository file, failed `apt-get update`, unsupported distribution, or typo in package name.
- GPG or signature errors: wrong key path, expired/intercepted certificate, incorrect clock, or proxy rewriting TLS.
- `Cannot connect to the Docker daemon`: Docker service inactive, current user lacks socket permission, or systemd is unavailable.
- `permission denied /var/run/docker.sock`: use `sudo docker ...` first; for non-root use, add the user to `docker` group and require a new login session.
- Port bind failure: check `ss -ltnp` and move the host port, for example `8080:80` instead of `80:80`.
- MySQL `Access denied`: check whether an existing volume skipped initialization, inspect logs, and verify the password source.
- Repository timeout: verify DNS, proxy, firewall egress, mirror policy, and whether a domestic mirror is required.
