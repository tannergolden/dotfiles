# --- Bootstrap: blank Windows machine to working environment ---
#
# Run from PowerShell 7 or later:
#   & $HOME\.dotfiles\scripts\bootstrap.ps1
#
# If it will not run at all, the execution policy is why. See the note at
# the end of this file.

#Requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$SkipPackages
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ChezmoiVersion = 'v2.71.1'
$RepoDir  = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Stamp    = (Get-Date -Format 'yyyyMMddTHHmmssZ')
$BackupDir = Join-Path $HOME ".dotfiles-backup-$Stamp"

function Write-Step { param($m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host "warn $m" -ForegroundColor Yellow }

Write-Step "repository: $RepoDir"

# --- stage 0: chezmoi ------------------------------------------------------
# Pinned and installed per-user. Deliberately not piping the install
# endpoint to a shell: its PowerShell one-liner has a documented history of
# breaking on fresh Windows 11, and the winget package once tripped a
# Defender false positive.
$BinDir = Join-Path $HOME '.local\bin'
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

$chezmoi = Get-Command chezmoi -ErrorAction SilentlyContinue
if (-not $chezmoi) {
    $local:exe = Join-Path $BinDir 'chezmoi.exe'
    if (Test-Path $local:exe) {
        $chezmoi = $local:exe
    } else {
        $arch = if ([Environment]::Is64BitOperatingSystem) { 'amd64' } else { '386' }
        $ver  = $ChezmoiVersion.TrimStart('v')
        $zip  = "chezmoi_${ver}_windows_${arch}.zip"
        $url  = "https://github.com/twpayne/chezmoi/releases/download/$ChezmoiVersion/$zip"
        $tmp  = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([guid]::NewGuid()))

        Write-Step "installing chezmoi $ChezmoiVersion (windows/$arch)"
        Invoke-WebRequest -Uri $url -OutFile (Join-Path $tmp $zip) -UseBasicParsing

        # Verify against the checksums published with the release. This
        # catches a corrupted or swapped artifact. It does not defend
        # against a compromised release process, because the checksum file
        # comes from the same origin.
        $sumUrl = "https://github.com/twpayne/chezmoi/releases/download/$ChezmoiVersion/chezmoi_${ver}_checksums.txt"
        $sums   = (Invoke-WebRequest -Uri $sumUrl -UseBasicParsing).Content
        $want   = ($sums -split "`n" | Where-Object { $_ -match [regex]::Escape($zip) }) -split '\s+' | Select-Object -First 1
        $got    = (Get-FileHash -Path (Join-Path $tmp $zip) -Algorithm SHA256).Hash.ToLower()
        if ($want -and ($want.ToLower() -ne $got)) {
            throw "checksum mismatch for ${zip}: expected $want, got $got"
        }

        Expand-Archive -Path (Join-Path $tmp $zip) -DestinationPath $tmp -Force
        Copy-Item -Path (Join-Path $tmp 'chezmoi.exe') -Destination $local:exe -Force
        Remove-Item -Recurse -Force $tmp
        $chezmoi = $local:exe
    }
} else {
    $chezmoi = $chezmoi.Source
}
Write-Step "chezmoi: $chezmoi"

# --- stage 1: back up ------------------------------------------------------
# chezmoi apply overwrites silently and is not atomic. On Windows it is
# worse: there are no atomic writes at all, so an interrupted apply can
# truncate a file. The snapshot is the only way back.
Write-Step "snapshotting existing targets to $BackupDir"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

$manifest = Join-Path $BackupDir 'manifest.tsv'
$stage    = Join-Path $BackupDir 'stage'
New-Item -ItemType Directory -Path $stage -Force | Out-Null
$rows = @()

$targets = & $chezmoi managed --source="$RepoDir" --path-style=absolute `
    --exclude=scripts,remove 2>$null
foreach ($t in $targets) {
    if ([string]::IsNullOrWhiteSpace($t)) { continue }
    $rel = $t.Substring($HOME.Length).TrimStart('\', '/')
    if (Test-Path -LiteralPath $t) {
        $item = Get-Item -LiteralPath $t -Force
        if ($item.PSIsContainer) {
            $rows += "dir`t$rel`t-"
        } else {
            $rows += "file`t$rel`t$([int]$item.IsReadOnly)"
            $dest = Join-Path $stage $rel
            New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $t -Destination $dest -Force
        }
    } else {
        # The row that makes an undo possible: restore must DELETE these.
        $rows += "absent`t$rel`t-"
    }
}
$rows | Set-Content -Path $manifest -Encoding utf8

if ((Get-ChildItem $stage -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
    Compress-Archive -Path (Join-Path $stage '*') `
        -DestinationPath (Join-Path $BackupDir 'targets.zip') -Force
}
Remove-Item -Recurse -Force $stage
Write-Step "$($rows.Count) target(s) recorded"

# --- stage 2: apply --------------------------------------------------------
Write-Step "applying dotfiles"
if ($SkipPackages) { $env:CI_STUB = '1' }

$interactive = [Environment]::UserInteractive -and (-not $env:CI)
if ($interactive) {
    & $chezmoi init --apply --source="$RepoDir"
} else {
    & $chezmoi init --apply --source="$RepoDir" --promptDefaults --no-tty
}

# --- stage 3: report -------------------------------------------------------
& $chezmoi verify --source="$RepoDir"
if ($LASTEXITCODE -eq 0) {
    Write-Step "target state matches source state"
} else {
    Write-Warn "drift reported by 'chezmoi verify'; run 'chezmoi diff' to inspect"
}

Write-Host @"

  Bootstrap complete.

  Backup of everything that existed beforehand:
    $BackupDir

"@

# --- execution policy ------------------------------------------------------
# The default on Windows 10 and 11 clients is Restricted, which blocks all
# script files INCLUDING profiles. Bypass on this invocation does nothing
# for tomorrow's shell. Reported rather than changed: silently mutating a
# machine's persistent security policy from a public repository is not
# something a bootstrap should do unasked.
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -in @('Restricted', 'Undefined')) {
    Write-Warn @"
Execution policy for CurrentUser is '$policy'.
Your PowerShell profile will NOT load until this changes:

    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Per-user, no administrator rights needed.
"@
}
