# --- Undo a Windows bootstrap ---
#
# Run from PowerShell 7 or later:
#   & $HOME\.dotfiles\scripts\restore-backup.ps1 $HOME\.dotfiles-backup-<stamp>
#
# WHY THIS FILE HAD TO EXIST.
#
# bootstrap.ps1 writes its snapshot with Compress-Archive, which produces
# targets.zip. restore-backup.sh looks for targets.tar.gz and, finding
# none, logged "no archive present (nothing existed at backup time)" and
# restored nothing. So on Windows the documented undo deleted the files
# bootstrap had created and never put the originals back, while reporting
# success. Both halves of that are fixed: this script reads the format
# Windows actually writes, and restore-backup.sh now refuses a snapshot it
# cannot read instead of treating it as empty.
#
# The order of operations mirrors the POSIX script exactly:
#   0. verify everything before touching a single file
#   1. delete every path the manifest marked `absent`
#   2. expand the archive over $HOME
#   3. re-assert the recorded read-only flags

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$BackupDir
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step { param($m) Write-Host "==> $m" -ForegroundColor Cyan }
function Stop-Restore { param($m) Write-Error "restore: $m"; exit 1 }

$manifestPath = Join-Path $BackupDir 'manifest.tsv'
$bundle       = Join-Path $BackupDir 'targets.zip'
$dest         = $HOME

# --- 0. everything that must be true BEFORE a single file is touched ------
#
# Step 1 deletes. Every check that can be made up front is made up front,
# because a failure after the deletions begin leaves a home directory with
# the new files gone and the old ones not yet back.

if ([string]::IsNullOrWhiteSpace($dest)) { Stop-Restore 'HOME is unset; refusing to guess where to restore' }
if (-not (Test-Path -LiteralPath $dest -PathType Container)) { Stop-Restore "HOME ($dest) is not a directory" }
if (-not (Test-Path -LiteralPath $BackupDir -PathType Container)) { Stop-Restore "no such backup directory: $BackupDir" }
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { Stop-Restore "no manifest at $manifestPath" }

$rows = @(Get-Content -LiteralPath $manifestPath -Encoding utf8 | Where-Object { $_ -ne '' })
if ($rows.Count -eq 0) { Stop-Restore "manifest at $manifestPath is empty" }

# A manifest row is three tab-separated fields. Anything else means the
# file was truncated or edited, and acting on half a manifest deletes a
# real file on the strength of a corrupt line.
$parsed = foreach ($row in $rows) {
    $f = $row -split "`t"
    if ($f.Count -ne 3) { Stop-Restore "manifest has a malformed row: $row" }
    [pscustomobject]@{ Kind = $f[0]; Rel = $f[1]; Extra = $f[2] }
}

# A relative path must never be absolute and never climb out of $HOME. The
# manifest is generated locally, so this guards against corruption rather
# than an attacker, but the operation it guards cannot be undone.
function Test-SafeRelativePath {
    param([string]$Rel)
    if ([string]::IsNullOrWhiteSpace($Rel)) { return $false }
    if ([System.IO.Path]::IsPathRooted($Rel)) { return $false }
    if ($Rel -match '(^|[\\/])\.\.([\\/]|$)') { return $false }
    return $true
}

foreach ($row in $parsed) {
    if (-not (Test-SafeRelativePath $row.Rel)) {
        Stop-Restore "manifest names a path outside HOME: $($row.Rel)"
    }
}

# THE ARCHIVE IS VERIFIED BEFORE THE DELETIONS, not after. Opening the zip
# and reading its entry list costs a fraction of a second and makes
# "deleted everything, then found the archive was corrupt" unreachable.
$hadContent = @($parsed | Where-Object { $_.Kind -in @('file', 'dir') }).Count -gt 0
if (Test-Path -LiteralPath $bundle -PathType Leaf) {
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($bundle)
        $entryCount = $zip.Entries.Count
        $zip.Dispose()
    } catch {
        Stop-Restore "$bundle is unreadable ($($_.Exception.Message)); refusing to delete anything"
    }
    Write-Step "archive verified: $entryCount entr$(if ($entryCount -eq 1) { 'y' } else { 'ies' })"
} elseif ($hadContent) {
    # The mirror of the check in restore-backup.sh: a snapshot taken by the
    # POSIX bootstrap is a .tar.gz, and this script cannot read it.
    if (Test-Path -LiteralPath (Join-Path $BackupDir 'targets.tar.gz')) {
        Stop-Restore 'this snapshot holds targets.tar.gz, written by bootstrap.sh; undo it with scripts/restore-backup.sh'
    }
    Stop-Restore "manifest records files that existed, but $bundle is missing"
}

# --- 1. remove what apply created -----------------------------------------
#
# Deepest paths first, so children go before their parents.
Write-Step 'removing paths that did not exist before bootstrap'
$removed = 0
$absent = $parsed |
    Where-Object { $_.Kind -eq 'absent' } |
    Sort-Object -Property Rel -Descending
foreach ($row in $absent) {
    $target = Join-Path $dest $row.Rel
    if (Test-Path -LiteralPath $target) {
        try {
            Remove-Item -LiteralPath $target -Recurse -Force
        } catch {
            Stop-Restore "could not remove ${target}: $($_.Exception.Message)"
        }
        Write-Host "  removed $($row.Rel)"
        $removed++
    }
}
Write-Step "removed $removed path(s) that bootstrap had created"

# --- 2. put back what was there -------------------------------------------
if (Test-Path -LiteralPath $bundle -PathType Leaf) {
    Write-Step 'restoring archived targets'
    try {
        Expand-Archive -LiteralPath $bundle -DestinationPath $dest -Force
    } catch {
        Stop-Restore "extraction failed ($($_.Exception.Message)); $dest is partially restored, archive intact at $bundle"
    }
} else {
    Write-Step 'no archive present (nothing existed at backup time)'
}

# --- 3. re-assert the recorded read-only flags ----------------------------
#
# NTFS carries no POSIX mode bits, so the read-only attribute is the only
# part of a file's mode the Windows snapshot can record and return. An
# `Extra` of `-` means it was not recorded, and those are skipped rather
# than guessed at.
Write-Step 'restoring recorded read-only flags'
$restoredFlags = 0
$skippedFlags  = 0
foreach ($row in $parsed) {
    if ($row.Kind -ne 'file') { continue }
    $target = Join-Path $dest $row.Rel
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
    switch ($row.Extra) {
        '0' { (Get-Item -LiteralPath $target -Force).IsReadOnly = $false; $restoredFlags++ }
        '1' { (Get-Item -LiteralPath $target -Force).IsReadOnly = $true;  $restoredFlags++ }
        default { $skippedFlags++ }
    }
}
$note = "  $restoredFlags flag(s) restored"
if ($skippedFlags -gt 0) { $note += ", $skippedFlags unrecorded at backup time" }
Write-Host $note

# --- 4. put back anything -Reset cleared ----------------------------------
#
# reset-conflicts.ps1 preserves each file it removes into conflicts\ and
# records it in conflicts.tsv. Kept separate from the main archive so a
# reader can see at a glance which files were removed for conflicting
# rather than merely overwritten.
$conflictsTsv = Join-Path $BackupDir 'conflicts.tsv'
$conflictsDir = Join-Path $BackupDir 'conflicts'
if (Test-Path -LiteralPath $conflictsTsv -PathType Leaf) {
    Write-Step 'restoring configuration that -Reset cleared'
    $restoredConflicts = 0
    foreach ($line in (Get-Content -LiteralPath $conflictsTsv -Encoding utf8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split "`t", 2
        if ($parts.Count -ne 2) { Stop-Restore "conflicts.tsv has a malformed row: $line" }
        $rel  = $parts[0]
        $flag = $parts[1]
        if (-not (Test-SafeRelativePath $rel)) {
            Stop-Restore "conflicts.tsv names a path outside HOME: $rel"
        }
        $staged = Join-Path $conflictsDir $rel
        if (-not (Test-Path -LiteralPath $staged)) {
            Stop-Restore "conflicts.tsv lists $rel but $staged is missing"
        }
        $target = Join-Path $HOME $rel
        $parent = Split-Path $target -Parent
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        try {
            Copy-Item -LiteralPath $staged -Destination $target -Recurse -Force
        } catch {
            Stop-Restore "could not restore ${rel}: $($_.Exception.Message)"
        }
        if ($flag -eq '1' -and (Test-Path -LiteralPath $target -PathType Leaf)) {
            (Get-Item -LiteralPath $target -Force).IsReadOnly = $true
        }
        Write-Host "  restored $rel"
        $restoredConflicts++
    }
    Write-Step "restored $restoredConflicts file(s) that -Reset had cleared"
}

Write-Step "restore complete from $BackupDir"
