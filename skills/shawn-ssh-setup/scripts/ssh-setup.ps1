[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('check-tools', 'ensure-key', 'show-public-key', 'test-connection')]
    [string]$Action,

    [string]$Alias,
    [string]$ServerHost,
    [int]$Port = 22,
    [string]$User,
    [string]$IdentityFile,
    [string]$SshDirectory,
    [string]$SshPath,
    [string]$KeygenPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Resolve-NativeTool {
    param([string]$Name, [string]$ExplicitPath)

    if ($ExplicitPath) {
        $resolved = [IO.Path]::GetFullPath((Expand-UserPath $ExplicitPath))
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            throw "$Name was not found at: $resolved"
        }
        return $resolved
    }

    $systemPath = Join-Path (Join-Path $env:WINDIR 'System32\OpenSSH') $Name
    if (Test-Path -LiteralPath $systemPath -PathType Leaf) {
        return [IO.Path]::GetFullPath($systemPath)
    }

    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        throw "$Name was not found. Enable the Windows OpenSSH Client optional feature, then retry."
    }
    return $command.Source
}

function Expand-UserPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $homePath = $env:USERPROFILE
    if (-not $homePath) { $homePath = [Environment]::GetFolderPath('UserProfile') }
    if ($Path -eq '~') { return $homePath }
    if ($Path.StartsWith('~/') -or $Path.StartsWith('~\')) {
        return Join-Path $homePath $Path.Substring(2)
    }
    return $Path
}

function Assert-Alias {
    param([Parameter(Mandatory = $true)][string]$Value)

    $normalized = $Value.Normalize([Text.NormalizationForm]::FormC)
    if ($normalized.Length -lt 1 -or $normalized.Length -gt 64 -or
        $normalized -notmatch '^[\p{L}\p{Nd}](?:[\p{L}\p{Nd}_-]{0,62}[\p{L}\p{Nd}])?$') {
        throw 'Alias must be 1-64 Unicode letters/digits, hyphens, or underscores, and must start and end with a letter or digit.'
    }
    return $normalized
}

function Assert-ConnectionInput {
    if ([string]::IsNullOrEmpty($ServerHost) -or
        $ServerHost.Length -gt 253 -or
        $ServerHost.StartsWith('-') -or
        $ServerHost -notmatch '^[A-Za-z0-9._:%-]+$') {
        throw 'ServerHost must be an IPv4 address, IPv6 address, or DNS name without whitespace or shell metacharacters.'
    }
    if ($Port -lt 1 -or $Port -gt 65535) { throw 'Port must be an integer from 1 to 65535.' }
    if ($null -eq $User -or $User.Length -eq 0) { throw 'User is required.' }
}

function Get-StandardIdentityPath {
    param([Parameter(Mandatory = $true)][string]$HostName)

    if ($SshDirectory) {
        $directory = [IO.Path]::GetFullPath((Expand-UserPath $SshDirectory))
    } else {
        $directory = Join-Path (Expand-UserPath '~') '.ssh'
    }

    # Colons are valid in IPv6 addresses but invalid in Windows file names.
    $hostComponent = $HostName.Replace(':', '_')
    return Join-Path $directory ("shawn_ssh_{0}_ed25519" -f $hostComponent)
}

function Get-IdentityPath {
    if ([string]::IsNullOrEmpty($IdentityFile)) { throw 'IdentityFile is required.' }
    return [IO.Path]::GetFullPath((Expand-UserPath $IdentityFile))
}

function Write-Json {
    param([Parameter(Mandatory = $true)]$Value)
    $Value | ConvertTo-Json -Depth 5
}

try {
    switch ($Action) {
        'check-tools' {
            $resolvedSsh = Resolve-NativeTool 'ssh.exe' $SshPath
            $resolvedKeygen = Resolve-NativeTool 'ssh-keygen.exe' $KeygenPath
            Write-Json ([ordered]@{ ssh = $resolvedSsh; ssh_keygen = $resolvedKeygen })
        }

        'ensure-key' {
            $normalizedAlias = Assert-Alias $Alias
            if ([string]::IsNullOrEmpty($ServerHost) -or $ServerHost -notmatch '^[A-Za-z0-9._:%-]+$') {
                throw 'ServerHost is required and contains unsupported characters.'
            }
            $identity = Get-StandardIdentityPath $ServerHost
            $publicKey = $identity + '.pub'
            $directory = Split-Path -Parent $identity
            if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
            }

            if ((Test-Path -LiteralPath $identity -PathType Leaf) -and (Test-Path -LiteralPath $publicKey -PathType Leaf)) {
                $status = 'reused'
            } else {
                Remove-Item -LiteralPath $identity -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $publicKey -Force -ErrorAction SilentlyContinue
                $resolvedKeygen = Resolve-NativeTool 'ssh-keygen.exe' $KeygenPath
                $comment = "shawn-ssh-setup:{0}@{1}" -f $Alias, $ServerHost
                # Windows PowerShell 5.1 drops empty native arguments; quoted-empty preserves -N "".
                $emptyPassphrase = ''
                if ($PSVersionTable.PSVersion.Major -lt 7) { $emptyPassphrase = '""' }
                $arguments = @('-q', '-t', 'ed25519', '-N', $emptyPassphrase, '-C', $comment, '-f', $identity)
                & $resolvedKeygen @arguments
                if ($LASTEXITCODE -ne 0 -or
                    -not (Test-Path -LiteralPath $identity -PathType Leaf) -or
                    -not (Test-Path -LiteralPath $publicKey -PathType Leaf)) {
                    throw "ssh-keygen failed with exit code $LASTEXITCODE."
                }
                $status = 'generated'
            }
            Write-Json ([ordered]@{ status = $status; alias = $Alias; normalized_alias = $normalizedAlias; identity_file = $identity; public_key_file = $publicKey })
        }

        'show-public-key' {
            $identity = Get-IdentityPath
            $publicKeyFile = $identity + '.pub'
            if (-not (Test-Path -LiteralPath $publicKeyFile -PathType Leaf)) { throw "Public key was not found: $publicKeyFile" }
            $publicKeyText = (Get-Content -LiteralPath $publicKeyFile -Raw).Trim()
            Write-Json ([ordered]@{ identity_file = $identity; public_key_file = $publicKeyFile; public_key = $publicKeyText })
        }

        'test-connection' {
            Assert-ConnectionInput
            $identity = Get-IdentityPath
            if (-not (Test-Path -LiteralPath $identity -PathType Leaf)) { throw "Private key was not found: $identity" }
            $resolvedSsh = Resolve-NativeTool 'ssh.exe' $SshPath
            $arguments = @(
                '-o', 'BatchMode=yes',
                '-o', 'StrictHostKeyChecking=yes',
                '-o', 'IdentitiesOnly=yes',
                '-o', 'ConnectTimeout=10',
                '-i', $identity,
                '-p', [string]$Port,
                '-l', $User,
                '--', $ServerHost,
                "printf 'SSH_OK'"
            )
            $output = @(& $resolvedSsh @arguments 2>&1 | ForEach-Object { $_.ToString() })
            $exitCode = $LASTEXITCODE
            $text = $output -join "`n"
            if ($exitCode -ne 0 -or $text -notmatch 'SSH_OK') {
                throw "Passwordless SSH validation failed (exit $exitCode). Output: $text"
            }
            Write-Json ([ordered]@{ success = $true; output = $text; ssh = $resolvedSsh; identity_file = $identity })
        }
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
