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
function Stop-Bootstrap { param($m) Write-Error "bootstrap: $m"; exit 1 }

# $ErrorActionPreference DOES NOT COVER NATIVE COMMANDS, which is the trap
# this script kept falling into. `chezmoi` is an executable, not a cmdlet,
# so a non-zero exit sets $LASTEXITCODE and execution carries straight on.
# Every chezmoi invocation below is therefore followed by this check, and
# without it a failed apply printed its error and then "Bootstrap
# complete." underneath.
function Assert-LastExitCode {
    param([string]$What)
    if ($LASTEXITCODE -ne 0) {
        Stop-Bootstrap "$What failed with exit code $LASTEXITCODE"
    }
}

Write-Step "repository: $RepoDir"

if (-not (Test-Path -LiteralPath (Join-Path $RepoDir 'home') -PathType Container)) {
    Stop-Bootstrap "no source state at $(Join-Path $RepoDir 'home'); is $RepoDir the repository root?"
}
if ([string]::IsNullOrWhiteSpace($HOME)) {
    Stop-Bootstrap 'HOME is unset; refusing to guess where to write'
}

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
        $line   = @($sums -split "`r?`n" | Where-Object { $_ -match "\s$([regex]::Escape($zip))`$" })
        # A MISSING CHECKSUM IS A FAILURE, NOT A PASS. This was previously
        # `if ($want -and ...)`, so a checksums file that did not list this
        # artifact skipped verification entirely and installed the binary
        # anyway. The whole point of pinning is that the unexpected case
        # stops, and "the release does not contain what I asked for" is
        # exactly the unexpected case.
        if ($line.Count -ne 1) {
            Stop-Bootstrap "expected exactly one checksum line for $zip, found $($line.Count); refusing to install an unverified binary"
        }
        $want = ($line[0] -split '\s+' | Where-Object { $_ -ne '' } | Select-Object -First 1)
        if ([string]::IsNullOrWhiteSpace($want)) {
            Stop-Bootstrap "could not parse the checksum for $zip; refusing to install an unverified binary"
        }
        $got = (Get-FileHash -Path (Join-Path $tmp $zip) -Algorithm SHA256).Hash.ToLower()
        if ($want.ToLower() -ne $got) {
            Stop-Bootstrap "checksum mismatch for ${zip}: expected $want, got $got"
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

# RELATIVE PATHS, for the same reason backup-targets.sh uses them.
#
# This used to ask for --path-style=absolute and then take
# $t.Substring($HOME.Length) on faith. Two ways that went wrong and neither
# announced itself: a target shorter than $HOME threw an unhandled
# IndexOutOfRange and killed the bootstrap between the snapshot and the
# apply, and a target that merely did not start with $HOME produced a
# silently wrong relative path that the restore would later delete. Asking
# chezmoi for relative paths removes the arithmetic entirely.
$targets = & $chezmoi managed --source="$RepoDir" --path-style=relative `
    --exclude=scripts,remove
Assert-LastExitCode 'chezmoi managed'

$targets = @($targets | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($targets.Count -eq 0) {
    Stop-Bootstrap "chezmoi reports no managed targets for $RepoDir; nothing can be backed up, and apply would write unguarded"
}

foreach ($t in $targets) {
    # chezmoi emits native separators here; everything downstream, the
    # manifest included, is read by both this script and Git Bash.
    $rel = $t -replace '\\', '/'
    if ([System.IO.Path]::IsPathRooted($rel) -or $rel -match '(^|/)\.\.(/|$)') {
        Stop-Bootstrap "refusing an unsafe managed path: $t"
    }
    $full = Join-Path $HOME $rel
    if (Test-Path -LiteralPath $full) {
        $item = Get-Item -LiteralPath $full -Force
        if ($item.PSIsContainer) {
            $rows += "dir`t$rel`t-"
        } else {
            $rows += "file`t$rel`t$([int]$item.IsReadOnly)"
            $staged = Join-Path $stage $rel
            New-Item -ItemType Directory -Path (Split-Path $staged -Parent) -Force | Out-Null
            try {
                Copy-Item -LiteralPath $full -Destination $staged -Force
            } catch {
                Stop-Bootstrap "could not snapshot ${full}: $($_.Exception.Message)"
            }
        }
    } else {
        # The row that makes an undo possible: restore must DELETE these.
        $rows += "absent`t$rel`t-"
    }
}
$rows | Set-Content -Path $manifest -Encoding utf8

$stagedFiles = @(Get-ChildItem $stage -Recurse -File -ErrorAction SilentlyContinue)
if ($stagedFiles.Count -gt 0) {
    $zipPath = Join-Path $BackupDir 'targets.zip'
    try {
        Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath -Force
    } catch {
        Stop-Bootstrap "could not write ${zipPath}: $($_.Exception.Message)"
    }

    # PROVE THE ARCHIVE IS READABLE BEFORE APPLY OVERWRITES THE ORIGINALS.
    # The moment a corrupt snapshot matters is the moment it is too late to
    # check, so it is checked here, while the originals are still on disk.
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        $entryCount = @($zip.Entries | Where-Object { $_.Name -ne '' }).Count
        $zip.Dispose()
    } catch {
        Stop-Bootstrap "$zipPath was written but cannot be read back: $($_.Exception.Message)"
    }
    if ($entryCount -lt $stagedFiles.Count) {
        Stop-Bootstrap "archive holds $entryCount file(s) but $($stagedFiles.Count) were staged"
    }
} else {
    Set-Content -Path (Join-Path $BackupDir 'EMPTY') -Value 'nothing existed to back up' -Encoding utf8
}
Remove-Item -Recurse -Force $stage
Write-Step "$($rows.Count) target(s) recorded, $($stagedFiles.Count) captured"

# --- stage 2: apply --------------------------------------------------------
Write-Step "applying dotfiles"
if ($SkipPackages) { $env:CI_STUB = '1' }

$interactive = [Environment]::UserInteractive -and (-not $env:CI)
if ($interactive) {
    & $chezmoi init --apply --source="$RepoDir"
} else {
    & $chezmoi init --apply --source="$RepoDir" --promptDefaults --no-tty
}

# APPLY IS NOT ATOMIC, so a failure here leaves a home directory that is
# part old and part new. The snapshot taken above is the way out of that,
# and the one moment somebody needs to be told about it is now, rather than
# in a document they would have to know to go and read.
if ($LASTEXITCODE -ne 0) {
    Write-Host @"

  APPLY FAILED with exit code $LASTEXITCODE.

  chezmoi applies file by file, so this machine is part old and part new.
  Everything that existed beforehand was captured first. To put it back:

    & $RepoDir\scripts\restore-backup.ps1 $BackupDir

"@ -ForegroundColor Red
    exit 1
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
  To undo:
    & $RepoDir\scripts\restore-backup.ps1 $BackupDir

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
