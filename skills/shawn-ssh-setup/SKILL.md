---
name: shawn-ssh-setup
description: Configures, adds, updates, or verifies passwordless SSH from Windows to POSIX-shell Linux/Unix servers, then records verified connections in the current directory's AGENTS.md. Use only when the user explicitly asks to set up or validate SSH public-key login; do not invoke for general server questions or remote administration.
compatibility: Windows 10/11 with PowerShell and Windows OpenSSH Client; target server must provide SSH and a POSIX shell
disable-model-invocation: true
---

# Windows Passwordless SSH Setup

Configure one server at a time. This skill ends when public-key login is strictly verified and the current directory's `AGENTS.md` accurately records it. It does not perform later remote administration or remove configurations.

`{baseDir}` means this skill's directory. Run `scripts/ssh-setup.ps1` with `pwsh.exe -NoProfile -File` when available, otherwise `powershell.exe -NoProfile -File`. If script execution is blocked, add `-ExecutionPolicy Bypass`; this affects only that PowerShell process.

## Steps

### 1. Inspect local state

Run:

```powershell
powershell.exe -NoProfile -File "{baseDir}\scripts\ssh-setup.ps1" check-tools
```

Use the reported full paths. If `ssh.exe` or `ssh-keygen.exe` is absent, explain how to enable the Windows OpenSSH Client optional feature and stop; installation remains the user's action.

Read only `./AGENTS.md` in the current working directory. Do not search parent directories. Locate exact `<!-- passwordless-ssh:begin -->` and `<!-- passwordless-ssh:end -->` markers:

- More than one marker pair or unmatched markers: report the ambiguity and stop.
- One pair: require exactly one fenced YAML block inside it and validate it against **Managed block** below.
- No pair: treat the project as unconfigured; preserve all existing content.

This step is complete when the OpenSSH executable paths and the current directory's managed-block state are known.

### 2. Resolve one server configuration

For a new server, ask separately for `alias`, `host`, `port`, and `user`. Show `22` as the default for `port` and `root` as the default for `user`. If the user omits or submits an empty value for either field, resolve it to its default; `alias` and `host` have no defaults and must be provided. For verification without a named alias, list configured aliases and ask the user to choose one; never default to validating all servers.

Validate:

- `alias`: 1–64 Unicode letters/digits, `-`, or `_`; starts and ends with a letter or digit.
- Alias uniqueness: normalize to Unicode NFC and compare English letters case-insensitively while preserving the user's spelling for display.
- `host`: IPv4, IPv6, or DNS name containing no whitespace or shell metacharacters.
- `port`: omitted/empty becomes `22`; otherwise an integer `1`–`65535`.
- `user`: omitted/empty becomes `root`; otherwise unrestricted.

For an existing alias, show field-level differences before changing `host`, `port`, or `user`, and wait for confirmation. Keep its complete existing key pair. If its custom `identity_file` is missing, ask whether to restore the standard path instead; only the standard path may be generated automatically. Changing `host` also changes the proposed standard identity path.

Summarize `alias`, `host`, `port`, `user`, and proposed identity path, then wait for confirmation. This step is complete only after the user confirms one valid configuration.

### 3. Ensure the key

The standard identity is `~/.ssh/shawn_ssh_<host>_ed25519` (for example, `~/.ssh/shawn_ssh_192.168.1.2_ed25519`). For IPv6, replace each `:` in the filename component with `_`; if `host` is a DNS name, use that DNS name as the component. Generate or reuse it with:

```powershell
powershell.exe -NoProfile -File "{baseDir}\scripts\ssh-setup.ps1" ensure-key -Alias "<alias>" -ServerHost "<host>"
```

The script creates an unencrypted ED25519 key with comment `shawn-ssh-setup:<alias>@<host>`. A complete private/public pair is reused without an extra pairing check. If either half is absent, the script removes both remnants and generates a complete pair without backup. It never falls back to RSA.

Before this point, perform no ping, port scan, or other network probe. This step is complete when both key files exist and the script reports `generated` or `reused`.

### 4. Have the user install the public key

Display the public key:

```powershell
powershell.exe -NoProfile -File "{baseDir}\scripts\ssh-setup.ps1" show-public-key -IdentityFile "<full-private-key-path>"
```

Give the user these two equivalent installation commands and ask them to choose **exactly one**, according to the terminal they use. Replace the local public-key path and SSH destination with the confirmed values. Add `-p <port>` immediately after `ssh` only when the port is not `22`.

**PowerShell:**

```powershell
Get-Content "<full-private-key-path>.pub" | ssh <user>@<host> "mkdir -p ~/.ssh && tr -d '\015' >> ~/.ssh/authorized_keys"
```

**Git Bash:**

```bash
cat "<git-bash-public-key-path>" | ssh <user>@<host> "mkdir -p ~/.ssh && tr -d '\015' >> ~/.ssh/authorized_keys"
```

A public-key file created by Windows OpenSSH may itself use a CRLF line ending. PowerShell's text pipeline can normalize it, while Git Bash `cat` streams the original carriage return and may leave a visible `^M` (`\r`) at the end of the authorized-key line. Both commands therefore remove carriage returns remotely with POSIX `tr -d '\015'` for consistent output.

For Git Bash, convert the full Windows public-key path to Git Bash form, for example `C:\Users\Name\.ssh\key.pub` becomes `/c/Users/Name/.ssh/key.pub`. Example commands:

```powershell
Get-Content $env:USERPROFILE\.ssh\shawn_ssh_192.168.1.100_ed25519.pub | ssh root@192.168.1.100 "mkdir -p ~/.ssh && tr -d '\015' >> ~/.ssh/authorized_keys"
```

```bash
cat "/c/Users/Name/.ssh/shawn_ssh_192.168.1.100_ed25519.pub" | ssh root@192.168.1.100 "mkdir -p ~/.ssh && tr -d '\015' >> ~/.ssh/authorized_keys"
```

Keep each generated command on exactly one physical line. Tell the user to run only their chosen command in the matching terminal and personally handle the SSH password and first-host-key prompt. Either command makes one SSH connection and sends the public key through standard input. Running both, or repeating either one, appends a duplicate key; that is harmless for authentication but should be avoided.

The agent never receives, stores, forwards, or injects a password. If password login is disabled, direct the user to install the displayed key through a cloud console or an existing administrator session. Wait until the user confirms installation.

This step is complete only when the chosen command exits without an error and the user says the key was installed.

### 5. Strictly verify public-key login

Run:

```powershell
powershell.exe -NoProfile -File "{baseDir}\scripts\ssh-setup.ps1" test-connection -ServerHost "<host>" -Port <port> -User "<user>" -IdentityFile "<full-private-key-path>" -SshPath "<reported-ssh.exe>"
```

The script explicitly uses `BatchMode=yes`, `StrictHostKeyChecking=yes`, `IdentitiesOnly=yes`, `ConnectTimeout=10`, the configured identity, port and user, then runs `printf 'SSH_OK'`. Success requires exit code `0` and output containing `SSH_OK`.

On a host-key-change error, stop. Explain that server reinstallation, IP reuse, or a man-in-the-middle attack may be responsible; the user must verify the fingerprint and manually repair `known_hosts`. On any other failure, report the script's output and keep `AGENTS.md` unchanged.

This step is complete only when the strict test succeeds.

### 6. Commit the verified metadata to `./AGENTS.md`

Before writing, warn that server metadata may enter version control; leave `.gitignore` unchanged. Then create or precisely update the single managed block:

- Missing file: create the minimal template below as UTF-8.
- Existing file without markers: append the block at the end, preserving existing bytes/content and adding a separating newline as needed.
- Existing valid block: update only that block. Replace an alias only after its new configuration passes Step 5.
- Malformed entry: identify its missing/invalid fields, obtain corrected values, and replace it only after strict verification.
- Existing alias with unchanged fields and a newly regenerated key: leave `AGENTS.md` byte-for-byte unchanged after verification.

Serialize every YAML string as a double-quoted scalar, escaping `\`, `"`, and control characters. Store the standard identity as `~/.ssh/shawn_ssh_<host>_ed25519`, replacing IPv6 `:` characters with `_`; preserve a valid custom path as entered. Store no passwords, public-key contents, fingerprints, `schema_version`, vendor-specific files, or remote-operation safety rules.

This step is complete when exactly one valid managed block exists and every changed entry represents a connection that passed Step 5.

## Managed block

The only managed schema is:

````markdown
## SSH Servers

<!-- passwordless-ssh:begin -->
```yaml
ssh_client: ssh.exe
servers:
  - alias: "web-01"
    host: "192.168.1.2"
    port: 22
    user: "root"
    identity_file: "~/.ssh/shawn_ssh_192.168.1.2_ed25519"
```
<!-- passwordless-ssh:end -->
````

Required fields are top-level `ssh_client: ssh.exe`, a `servers` sequence, and string `alias`, string `host`, integer `port`, string `user`, and string `identity_file` for every server. Preserve server order when updating; append new aliases.

## Script contract

`scripts/ssh-setup.ps1` is non-interactive and has no third-party dependencies. It passes user values to native programs as argument arrays rather than executable shell strings. Its actions are:

| Action | Result |
|---|---|
| `check-tools` | Reports resolved `ssh.exe` and `ssh-keygen.exe` paths, preferring `%WINDIR%\System32\OpenSSH`. |
| `ensure-key` | Generates/reuses only the standard per-host ED25519 identity. |
| `show-public-key` | Returns the `.pub` content for display. |
| `test-connection` | Performs the strict non-interactive test and fails nonzero unless `SSH_OK` is observed. |
