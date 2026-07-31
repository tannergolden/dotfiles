# --- Clear the config that silently overrides this repository (Windows) ---
#
# Usage:
#   & reset-conflicts.ps1 <chezmoi> <repo-dir>                report only
#   & reset-conflicts.ps1 <chezmoi> <repo-dir> <backup-dir>   preserve, then remove
#
# The Windows half of scripts/reset-conflicts.sh, and the reasoning there
# applies here unchanged: a machine can differ from this repository in a
# way `chezmoi verify` cannot see, because the files responsible are ones
# chezmoi does not manage.
#
# THE TWO THAT MATTER ON WINDOWS.
#
# ~/.gitconfig, for the same reason as everywhere else: Git reads it and
# it beats ~/.config/git/config outright.
#
# Documents\PowerShell\Microsoft.PowerShell_profile.ps1, which is subtler.
# PowerShell loads four profiles in a fixed order, ending
# CurrentUserAllHosts then CurrentUserCurrentHost. The shim this
# repository writes is profile.ps1, which is CurrentUserAllHosts, so a
# Microsoft.PowerShell_profile.ps1 sitting beside it loads AFTERWARDS and
# wins every conflict between them. Nothing announces that.
#
# WHAT IT WILL NOT TOUCH: Windows Terminal's settings.json. That file
# holds every profile and every setting, not only the colour scheme this
# repository contributes, and the scheme arrives as a fragment precisely
# so the settings file never has to be rewritten.
#
# REPORTING IS THE DEFAULT. Removal happens only when a backup directory
# is given, and every removed file is preserved into it first.

#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)] [string]$Chezmoi,
    [Parameter(Mandatory = $true, Position = 1)] [string]$RepoDir,
    [Parameter(Position = 2)] [string]$BackupDir = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($HOME)) { Write-Error 'reset: HOME is unset'; exit 1 }

$mode          = if ([string]::IsNullOrWhiteSpace($BackupDir)) { 'report' } else { 'remove' }
$conflictsDir  = if ($mode -eq 'remove') { Join-Path $BackupDir 'conflicts' } else { $null }
$conflictsTsv  = if ($mode -eq 'remove') { Join-Path $BackupDir 'conflicts.tsv' } else { $null }

$found = 0; $removed = 0; $noted = 0

# Preserve first, remove second. A file whose preservation failed is never
# removed, which is the whole reason this is safe to run.
function Invoke-Take {
    param([string]$Rel, [string]$Why)
    $script:found++
    $target = Join-Path $HOME $Rel

    if ($mode -eq 'report') {
        Write-Host ("  would remove  {0,-40} {1}" -f $Rel, $Why)
        return
    }

    $staged = Join-Path $conflictsDir $Rel
    $parent = Split-Path $staged -Parent
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    try {
        Copy-Item -LiteralPath $target -Destination $staged -Recurse -Force
    } catch {
        Write-Error "reset: could not preserve $Rel ($($_.Exception.Message)); refusing to remove it"
        exit 1
    }

    # The read-only flag, which is all of a mode NTFS carries.
    $item = Get-Item -LiteralPath $target -Force
    $flag = if ($item.PSIsContainer) { '-' } else { [int]$item.IsReadOnly }
    Add-Content -Path $conflictsTsv -Value ("{0}`t{1}" -f ($Rel -replace '\\', '/'), $flag) -Encoding utf8

    try {
        Remove-Item -LiteralPath $target -Recurse -Force
    } catch {
        Write-Error "reset: could not remove $target ($($_.Exception.Message))"
        exit 1
    }
    Write-Host ("  removed       {0,-40} {1}" -f $Rel, $Why)
    $script:removed++
}

function Invoke-Note {
    param([string]$Rel, [string]$Why)
    Write-Host ("  kept          {0,-40} {1}" -f $Rel, $Why)
    $script:noted++
}

Write-Host 'checking for configuration that overrides this repository'

# --- 1. files that win over a file this repository owns -------------------

if (Test-Path -LiteralPath (Join-Path $HOME '.gitconfig')) {
    Invoke-Take '.gitconfig' 'beats .config/git/config'
}

# Resolved at run time, never assumed to be under $HOME\Documents, because
# OneDrive Known Folder Move can relocate Documents by policy. Same
# resolution the shim script itself uses.
$documents = [Environment]::GetFolderPath('MyDocuments')
if (-not [string]::IsNullOrWhiteSpace($documents)) {
    foreach ($dir in @('PowerShell', 'WindowsPowerShell')) {
        $hostProfile = Join-Path $documents "$dir\Microsoft.PowerShell_profile.ps1"
        if (Test-Path -LiteralPath $hostProfile) {
            # Recorded relative to $HOME so restore can find it again. If
            # Documents sits outside $HOME the relative path would escape,
            # so that case is reported and left alone rather than removed.
            if ($hostProfile.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) {
                $rel = $hostProfile.Substring($HOME.Length).TrimStart('\', '/')
                Invoke-Take $rel 'loads after the profile shim and wins'
            } else {
                Invoke-Note $hostProfile 'overrides the shim, but sits outside HOME'
            }
        }
    }
}

# --- 2. orphans: applied here once, ignored on this platform now ----------

$ignored = & $Chezmoi ignored --source="$RepoDir" 2>$null
if ($LASTEXITCODE -eq 0 -and $ignored) {
    foreach ($rel in $ignored) {
        if ([string]::IsNullOrWhiteSpace($rel)) { continue }
        if ([System.IO.Path]::IsPathRooted($rel)) { continue }
        if ($rel -match '(^|[\\/])\.\.([\\/]|$)') { continue }
        # Repository infrastructure, ignored so it never reaches a home
        # directory. Not an orphan, and not going to be sitting in one.
        if ($rel -match '^(README\.md|LICENSE|Makefile|install\.sh)$') { continue }
        if ($rel -match '^(\.github|docs|scripts|packages)/') { continue }
        if (Test-Path -LiteralPath (Join-Path $HOME $rel)) {
            Invoke-Take $rel 'orphan: ignored on this platform'
        }
    }
}

# --- 3. deliberate divergence, reported and kept --------------------------

if (Test-Path -LiteralPath (Join-Path $HOME '.config\git\config.local')) {
    Invoke-Note '.config/git/config.local' 'your escape hatch, included last'
}

# --- summary --------------------------------------------------------------

if ($found -eq 0) {
    Write-Host '  nothing overriding this repository was found'
}

if ($mode -eq 'report') {
    if ($found -gt 0) {
        Write-Host ''
        Write-Host ("  {0} file(s) would be removed. Nothing was changed." -f $found)
        Write-Host '  Bootstrap with -Reset to remove them, preserved into the snapshot.'
    }
} else {
    Write-Host ("  {0} removed, {1} kept" -f $removed, $noted)
}

exit 0
