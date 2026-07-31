# --- Bootstrap: blank Windows machine to working environment ---
#
# THE ONE COMMAND, from any stock Windows PowerShell:
#
#   irm https://raw.githubusercontent.com/tannergolden/dotfiles/Development/scripts/bootstrap.ps1 | iex
#
# Or, from a clone: & $HOME\.dotfiles\scripts\bootstrap.ps1
#
# NO `#Requires -Version 7.0` AT THE TOP, DELIBERATELY, although the body
# needs 7. A stock machine has only Windows PowerShell 5.1, and #Requires
# would stop there with an instruction to a person - the exact manual step
# being removed. Instead the preamble below is written to PARSE under 5.1
# (no ternaries, no null-coalescing, no chain operators anywhere in this
# file), detects the downlevel host, installs PowerShell 7 through winget,
# and re-executes itself under it. The single UAC consent that raises is
# Windows' gate on machine-wide installs, not a decision this script asks
# anyone to make.

[CmdletBinding()]
param(
    [switch]$SkipPackages,

    # OFF BY DEFAULT. Every run reports what overrides this repository;
    # only a run that was explicitly asked to will remove any of it.
    # Everything removed is preserved into the snapshot first, so
    # restore-backup.ps1 puts it back.
    [switch]$Reset
)

$ErrorActionPreference = 'Stop'

# --- self-locate, self-fetch, self-upgrade ---------------------------------
# $MyInvocation has no path when this script arrives through `irm | iex`,
# which is the fingerprint of the one-command install: nothing is on disk
# yet. Fetch the repository first - git when a real one exists, the GitHub
# zipball otherwise - then hand over to the cloned copy of this same file.
function Find-Pwsh7 {
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $default = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    if (Test-Path $default) { return $default }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return $null }
    Write-Host '==> installing PowerShell 7 (one UAC consent; Windows'' gate on machine-wide installs)'
    winget install --exact --id Microsoft.PowerShell --silent `
        --accept-package-agreements --accept-source-agreements
    if (Test-Path $default) { return $default }
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$script:SelfPath = $MyInvocation.MyCommand.Path
if (-not $script:SelfPath) {
    $slug   = 'tannergolden/dotfiles'
    $ref    = if ($env:DOTFILES_REF) { $env:DOTFILES_REF } else { 'Development' }
    $target = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else { Join-Path $HOME '.dotfiles' }

    if (-not (Test-Path (Join-Path $target 'scripts\bootstrap.ps1'))) {
        if (Test-Path $target) {
            Write-Error "$target exists but is not this repository; move it aside first"
            exit 1
        }
        Write-Host "==> fetching $slug@$ref to $target"
        if (Get-Command git -ErrorAction SilentlyContinue) {
            git clone --branch $ref "https://github.com/$slug" $target
            if ($LASTEXITCODE -ne 0) { Write-Error 'git clone failed'; exit 1 }
        } else {
            # No git on a stock machine. The zipball needs nothing but
            # PowerShell itself; provisioning installs a real git later
            # and bootstrap grafts history back so updates work.
            $tmp = Join-Path $env:TEMP ([guid]::NewGuid())
            New-Item -ItemType Directory -Path $tmp -Force | Out-Null
            $zip = Join-Path $tmp 'dotfiles.zip'
            Invoke-WebRequest -UseBasicParsing -OutFile $zip `
                -Uri "https://codeload.github.com/$slug/zip/refs/heads/$ref"
            Expand-Archive -Path $zip -DestinationPath $tmp -Force
            # The zipball wraps everything in one top directory named
            # after the ref; unwrap it so the layout matches a clone.
            $inner = Get-ChildItem -Path $tmp -Directory | Select-Object -First 1
            Move-Item -Path $inner.FullName -Destination $target
            Remove-Item -Recurse -Force $tmp
        }
    }

    $script:SelfPath = Join-Path $target 'scripts\bootstrap.ps1'
}

if ($PSVersionTable.PSVersion.Major -lt 7 -or $MyInvocation.MyCommand.Path -ne $script:SelfPath) {
    # Either a downlevel host, or the piped copy handing over to the
    # fetched file (so $PSScriptRoot and every relative path work).
    # -ExecutionPolicy Bypass covers the fresh machine whose Restricted
    # policy would otherwise refuse the file before the policy stage
    # below has had its chance to fix that policy properly.
    $pwsh = Find-Pwsh7
    if (-not $pwsh) {
        Write-Error 'PowerShell 7 is required and winget could not provide it; install it from https://aka.ms/powershell and re-run'
        exit 1
    }
    $fwd = @()
    foreach ($k in $PSBoundParameters.Keys) { if ($PSBoundParameters[$k]) { $fwd += "-$k" } }
    & $pwsh -NoProfile -ExecutionPolicy Bypass -File $script:SelfPath @fwd
    exit $LASTEXITCODE
}

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
        # ARCHITECTURE FROM THE OS, NOT FROM BITNESS. `Is64BitOperatingSystem`
        # is true on an ARM64 machine too, so it named the amd64 build on a
        # Windows-on-ARM device - which runs, slowly, under emulation - and
        # named a 386 build that chezmoi's releases do not contain at all on
        # anything else, producing a 404 rather than a clear message.
        $arch = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture) {
            'Arm64' { 'arm64' }
            'X64'   { 'amd64' }
            default {
                Stop-Bootstrap "no chezmoi build for $_; install chezmoi manually and re-run"
            }
        }
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

# --- stage 0b: SSH keys ----------------------------------------------------
# BEFORE apply, because the git config template gates commit.gpgsign on the
# signing key existing at render time: a key generated now means signing is
# on from the very first apply. ssh-keygen ships with Windows' inbox
# OpenSSH client; the System32 probe covers a PATH that has not seen it.
#
# NO PASSPHRASE, STATED RATHER THAN HIDDEN: these keys never leave the
# machine, and install is one command with zero input. Generate your own
# passphrased keys under the same names and this stage will not touch them,
# it only ever fills absence.
$sshKeygen = $null
$cmd = Get-Command ssh-keygen -ErrorAction SilentlyContinue
if ($cmd) { $sshKeygen = $cmd.Source }
elseif (Test-Path (Join-Path $env:SystemRoot 'System32\OpenSSH\ssh-keygen.exe')) {
    $sshKeygen = Join-Path $env:SystemRoot 'System32\OpenSSH\ssh-keygen.exe'
}
if ($sshKeygen) {
    $sshDir = Join-Path $HOME '.ssh'
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    foreach ($pair in @(@('id_auth_ed25519', 'auth'), @('id_signing_ed25519', 'signing'))) {
        $keyPath = Join-Path $sshDir $pair[0]
        if (Test-Path $keyPath) {
            Write-Step "key exists: $keyPath"
        } else {
            & $sshKeygen -q -t ed25519 -N '' -C $pair[1] -f $keyPath
            if ($LASTEXITCODE -eq 0) { Write-Step "generated $keyPath" }
            else { Write-Warn "could not generate $keyPath; git works, commits stay unsigned" }
        }
    }
} else {
    Write-Warn 'ssh-keygen not found; skipping key setup (git still works, unsigned)'
}

# --- stage 1: back up ------------------------------------------------------
# chezmoi apply overwrites silently and is not atomic. On Windows it is
# worse: there are no atomic writes at all, so an interrupted apply can
# truncate a file. The snapshot is the only way back.
Write-Step "snapshotting existing targets to $BackupDir"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

$manifest = Join-Path $BackupDir 'manifest.tsv'
$stage    = Join-Path $BackupDir 'stage'

# REFUSE TO WRITE OVER AN EXISTING SNAPSHOT, which backup-targets.sh has
# always done and this side did not: Set-Content and Compress-Archive
# -Force both overwrite silently, so two runs landing on the same
# second-resolution stamp destroyed the only copy of the originals.
foreach ($existing in @('manifest.tsv', 'targets.zip')) {
    if (Test-Path -LiteralPath (Join-Path $BackupDir $existing)) {
        Stop-Bootstrap "$BackupDir already holds $existing; refusing to overwrite a snapshot"
    }
}

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

# HIDDEN FILES MUST REACH THE ARCHIVE, AND TWICE THEY DID NOT. Copy-Item
# preserves the Hidden attribute onto the staged copy, and then both
# `Compress-Archive -Path <dir>\*` (wildcard resolution skips hidden
# items) and an un-Forced Get-ChildItem skip them - so a target that
# happened to carry the attribute was staged, silently left out of the
# zip, AND left out of the count the verification compares, meaning the
# check could not see its own loss. Windows tools set Hidden on dotfiles
# often enough that this is a real path, not a curiosity. Clearing the
# attribute on the staged copies fixes both halves at once; the originals
# are untouched, and restore re-creates plain files, which is the same
# thing the POSIX side does.
Get-ChildItem $stage -Recurse -File -Force -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Attributes = [System.IO.FileAttributes]::Normal }

$stagedFiles = @(Get-ChildItem $stage -Recurse -File -Force -ErrorAction SilentlyContinue)
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

# --- stage 1b: conflicting configuration ----------------------------------
#
# AFTER the snapshot, so nothing is removed that has not already been
# recorded, and BEFORE the apply, so this repository's files land on a
# machine where nothing quietly outranks them.
$resetScript = Join-Path $RepoDir 'scripts\reset-conflicts.ps1'
if (Test-Path -LiteralPath $resetScript) {
    if ($Reset) {
        & $resetScript $chezmoi $RepoDir $BackupDir
        Assert-LastExitCode 'reset-conflicts.ps1'
    } else {
        # Reported on every run. Knowing that a stray ~/.gitconfig is
        # beating this configuration is worth more than the lines it costs.
        & $resetScript $chezmoi $RepoDir
        if ($LASTEXITCODE -ne 0) { Write-Warn 'could not check for conflicting configuration' }
    }
} else {
    Write-Warn "reset-conflicts.ps1 is missing; skipping the conflict check"
}

# --- stage 2: apply --------------------------------------------------------
Write-Step "applying dotfiles"
# SCOPED TO THE CHILD, NOT LEAKED INTO THIS SESSION. Setting $env:CI_STUB
# here left it set for the rest of the shell, so every later `chezmoi
# apply` a person typed in that same window silently stubbed every
# provisioning script - packages appearing to install and never doing so.
# It is restored in the finally block below, and chezmoi inherits it for
# the duration of the call either way.
$previousStub = $env:CI_STUB
if ($SkipPackages) { $env:CI_STUB = '1' }

# --promptDefaults ON EVERY RUN, interactive included: install is one
# command with zero input, and the declared defaults are this
# repository owner's identity rather than a guess.
try {
    $interactive = [Environment]::UserInteractive -and (-not $env:CI)
    if ($interactive) {
        & $chezmoi init --apply --source="$RepoDir" --promptDefaults
    } else {
        & $chezmoi init --apply --source="$RepoDir" --promptDefaults --no-tty
    }
} finally {
    $env:CI_STUB = $previousStub
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

# --- stage 4: the signing trust list ---------------------------------------
# AFTER apply, because allowed_signers is a `create_` target that does not
# exist until apply has run once. The email comes from the chezmoi data the
# init above persisted, so the trust entry matches the commit identity
# without asking anyone anything.
$signingPub = Join-Path $HOME '.ssh\id_signing_ed25519.pub'
$signers    = Join-Path $HOME '.config\git\allowed_signers'
if ((Test-Path $signingPub) -and (Test-Path $signers)) {
    $identityEmail = (& $chezmoi execute-template '{{ .email }}' 2>$null)
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($identityEmail)) {
        $keyBlob = ((Get-Content $signingPub -First 1) -split ' ')[0..1] -join ' '
        $already = Select-String -Path $signers -SimpleMatch $keyBlob -Quiet
        if ($already) {
            Write-Step 'signing key already in allowed_signers'
        } else {
            # namespaces="git" pins the signature context, exactly as the
            # allowed_signers file's own comments document.
            Add-Content -Path $signers -Value "$identityEmail namespaces=`"git`" $keyBlob"
            Write-Step "added signing key to allowed_signers for $identityEmail"
        }
    } else {
        Write-Warn 'could not read the commit email from chezmoi data; allowed_signers not updated'
    }
}

# --- stage 5: register the keys on GitHub, when a credential exists --------
# The one genuinely manual step left is telling GitHub about the new
# public keys, because that needs a credential no fresh machine holds. A
# machine that HAS one - gh already logged in - should not hand the job
# back to a person. Best effort, loud on both outcomes, never fatal.
$keysRegistered = $false
if ((-not $env:CI) -and (Get-Command gh -ErrorAction SilentlyContinue)) {
    gh auth status 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $regOk = $true
        foreach ($spec in @(
            @{ Path = Join-Path $HOME '.ssh\id_auth_ed25519.pub';    Type = 'authentication'; Title = 'auth' },
            @{ Path = Join-Path $HOME '.ssh\id_signing_ed25519.pub'; Type = 'signing';        Title = 'signing' }
        )) {
            if (-not (Test-Path $spec.Path)) { continue }
            $blob = ((Get-Content $spec.Path -First 1) -split ' ')[1]
            $listed = (gh ssh-key list 2>$null) -match [regex]::Escape($blob)
            if ($listed) { Write-Step "already on GitHub: $($spec.Path)"; continue }
            gh ssh-key add $spec.Path --type $spec.Type --title "$env:COMPUTERNAME $($spec.Title)" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Step "registered on GitHub ($($spec.Type)): $($spec.Path)"
            } else {
                Write-Warn "could not register $($spec.Path); if the token lacks scope, run: gh auth refresh -s admin:public_key,admin:ssh_signing_key"
                $regOk = $false
            }
        }
        $keysRegistered = $regOk
    }
}

# --- stage 6: execution policy ---------------------------------------------
# The default on Windows 10 and 11 clients is Restricted, which blocks all
# script files INCLUDING profiles: everything this bootstrap just installed
# would sit there and never load, which reads as "nothing was installed".
# Install is one command with zero input, so the per-user policy is set
# here, loudly, rather than printed as homework. RemoteSigned per-user is
# Microsoft's own recommendation for exactly this; no administrator rights
# are involved, and a group policy that pins the setting wins anyway - the
# catch below reports that honestly instead of pretending.
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -in @('Restricted', 'Undefined')) {
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Step "execution policy for CurrentUser: '$policy' -> RemoteSigned; the profile can now load"
    } catch {
        Write-Warn "could not change the execution policy (group policy may pin it): $($_.Exception.Message)"
    }
}

# --- stage 7: Windows Terminal picks the scheme ----------------------------
# The fragment under AppData ADDS the Catppuccin Mocha scheme, but a
# fragment cannot SELECT one - that used to be the documented manual step.
# Windows Terminal rewrites settings.json itself constantly, so editing it
# programmatically is normal for that file; comments it may contain are
# understood by ConvertFrom-Json and lost on rewrite, which the Terminal's
# own settings UI also does. A sidecar .bak preserves the exact previous
# bytes. Covers stable, preview and unpackaged installs; a machine with no
# Terminal at all is skipped silently.
$wtCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
)
foreach ($settingsPath in $wtCandidates) {
    $settingsDir = Split-Path $settingsPath -Parent
    if (Test-Path $settingsPath) {
        try {
            $wt = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
        } catch {
            Write-Warn "could not parse $settingsPath; leaving it alone"
            continue
        }
        if (-not $wt.ContainsKey('profiles')) { $wt['profiles'] = [ordered]@{} }
        if ($wt['profiles'] -is [System.Collections.IList]) {
            # The ancient list-only profiles format predates both defaults
            # and fragments; rewriting it wholesale risks more than a
            # colour scheme is worth.
            Write-Warn "$settingsPath uses the legacy profiles format; pick the scheme in Settings once"
            continue
        }
        if (-not $wt['profiles'].Contains('defaults')) { $wt['profiles']['defaults'] = [ordered]@{} }
        if ($wt['profiles']['defaults']['colorScheme'] -eq 'Catppuccin Mocha') {
            Write-Step "Windows Terminal already uses Catppuccin Mocha ($settingsPath)"
            continue
        }
        Copy-Item -LiteralPath $settingsPath -Destination "$settingsPath.pre-dotfiles.bak" -Force
        $wt['profiles']['defaults']['colorScheme'] = 'Catppuccin Mocha'
        $wt | ConvertTo-Json -Depth 64 | Set-Content -Path $settingsPath -Encoding utf8
        Write-Step "Windows Terminal default scheme set to Catppuccin Mocha (previous file at $settingsPath.pre-dotfiles.bak)"
    } elseif (Test-Path $settingsDir) {
        # Terminal is installed but has never run: a minimal settings file
        # is honoured on first launch, and the fragment supplies the
        # scheme definition itself.
        [ordered]@{ profiles = [ordered]@{ defaults = [ordered]@{ colorScheme = 'Catppuccin Mocha' } } } |
            ConvertTo-Json -Depth 8 | Set-Content -Path $settingsPath -Encoding utf8
        Write-Step "Windows Terminal will start on Catppuccin Mocha ($settingsPath)"
    }
}

# --- stage 8: a zipball install becomes a clone ----------------------------
# The one-command install fetches a zipball when git is missing.
# Provisioning has installed Git.Git by now (its PATH entry reaches new
# shells, not this one, hence the explicit probe), so graft history back
# so `chezmoi update` works from here on. Fresh install: reset --hard
# forfeits nothing.
if (-not (Test-Path (Join-Path $RepoDir '.git'))) {
    $git = $null
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) { $git = $cmd.Source }
    elseif (Test-Path (Join-Path $env:ProgramFiles 'Git\cmd\git.exe')) {
        $git = Join-Path $env:ProgramFiles 'Git\cmd\git.exe'
    }
    if ($git) {
        $ref = if ($env:DOTFILES_REF) { $env:DOTFILES_REF } else { 'Development' }
        Write-Step "turning the zipball at $RepoDir into a git clone ($ref)"
        & $git -C $RepoDir init -q -b $ref
        if ($LASTEXITCODE -eq 0) { & $git -C $RepoDir remote add origin 'https://github.com/tannergolden/dotfiles' }
        if ($LASTEXITCODE -eq 0) { & $git -C $RepoDir fetch -q origin $ref }
        if ($LASTEXITCODE -eq 0) { & $git -C $RepoDir reset -q --hard "origin/$ref" }
        if ($LASTEXITCODE -eq 0) { & $git -C $RepoDir branch -q --set-upstream-to="origin/$ref" }
        if ($LASTEXITCODE -eq 0) {
            Write-Step "history restored; future updates are 'chezmoi update'"
        } else {
            Write-Warn 'could not graft git history; installs still work, updates need a fresh clone'
        }
    }
}

# --- stage 9: report --------------------------------------------------------
Write-Host @"

  Bootstrap complete.

  Backup of everything that existed beforehand:
    $BackupDir
  To undo:
    & $RepoDir\scripts\restore-backup.ps1 $BackupDir

"@

if ((-not $keysRegistered) -and (Test-Path (Join-Path $HOME '.ssh\id_signing_ed25519.pub'))) {
    Write-Host @"
  One step needs a credential no fresh machine holds - telling GitHub
  about this machine's new public keys. Either sign in once and re-run
  bootstrap, which registers them for you:

    gh auth login

  or paste them yourself at https://github.com/settings/keys:

    ~\.ssh\id_auth_ed25519.pub       as an Authentication key
    ~\.ssh\id_signing_ed25519.pub    as a Signing key (a SEPARATE list)

"@
}
