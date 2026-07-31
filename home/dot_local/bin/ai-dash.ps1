# --- ai-dash: the 2x2 terminal dashboard, Windows Terminal edition ---
#
#   +----------------+----------------+
#   | fastfetch      | (blank shell)  |
#   +----------------+----------------+
#   | ai-agents      | ai-model chat  |
#   +----------------+----------------+
#
# WHY wt AND NOT tmux. tmux has no native Windows build (WSL/MSYS2 only),
# and Windows Terminal has a real pane CLI, so the same `ai-dash` command
# is delivered through the platform's own mechanism - exactly the parity
# rule the README describes: identical command, different machinery.
#
# THE SEMICOLONS ARE THE WHOLE TRICK. `wt` separates its subcommands with
# `;`, which PowerShell would otherwise consume as its own statement
# separator. Building ONE argument string and handing it to Start-Process
# sidesteps the documented backtick-escaping dance entirely, and also
# avoids the documented blocking behaviour where the calling shell waits
# for the Terminal window to close.
#
# PANE ORDER. wt focuses each new pane as it is created, so the grid is
# walked explicitly: full pane -> vertical split (right half) -> focus
# left -> horizontal split (bottom-left) -> focus right -> horizontal
# split (bottom-right). -H stacks top/bottom, -V splits side-by-side.
# Every pane runs pwsh -NoExit so it drops to a usable shell when its
# command finishes - the wt analogue of the POSIX script's 'cmd; exec sh'.
#
# NO LITERAL SEMICOLON MAY APPEAR INSIDE A PANE'S COMMAND STRING. wt
# splits its command line on ; BEFORE any quoting is considered, so a
# semicolon inside a -Command message truncates that pane's command and
# feeds the remainder to wt as garbage subcommands. Every string below is
# written semicolon-free rather than escaped, because an escape another
# editor cannot see is a trap.

param(
    [Parameter(Position = 0)]
    [ValidateSet('open', 'kill')]
    [string]$Command = 'open'
)

$ErrorActionPreference = 'Stop'

if ($Command -eq 'kill') {
    # The POSIX twin kills a detached tmux session. Windows Terminal has
    # no session concept to kill - closing the dashboard window IS the
    # whole teardown - so this exists to answer the same command honestly
    # rather than silently opening a second dashboard.
    Write-Host 'Windows Terminal has no detached session: closing the ai-dash window is the whole teardown.'
    exit 0
}

if (-not (Get-Command wt -ErrorAction SilentlyContinue)) {
    Write-Warning 'ai-dash needs Windows Terminal (wt) for panes.'
    Write-Host 'Install it with: winget install --exact --id Microsoft.WindowsTerminal'
    exit 1
}

# Sibling scripts by absolute path: the child pwsh processes load the
# profile (which puts ~/.local/bin on PATH), but an absolute path does not
# gamble on that, and it survives being launched from any directory. The
# doubled apostrophes are PowerShell's escape for ' inside a
# single-quoted string, without which a user profile path containing an
# apostrophe (C:\Users\O'Brien) breaks both bottom panes.
$agents = (Join-Path $PSScriptRoot 'ai-agents.ps1').Replace("'", "''")
$chat   = (Join-Path $PSScriptRoot 'ai-model.ps1').Replace("'", "''")

# fastfetch degrades to a plain message rather than a dead pane if the
# package has not landed yet.
$sysinfo = "if (Get-Command fastfetch -ErrorAction SilentlyContinue) { fastfetch } else { 'fastfetch is not installed - run chezmoi apply' }"

$panes = @(
    "new-tab --title ai-dash pwsh -NoExit -Command ""$sysinfo"""
    "split-pane -V pwsh -NoExit"
    "move-focus left"
    "split-pane -H pwsh -NoExit -Command ""& '$agents'"""
    "move-focus right"
    "split-pane -H pwsh -NoExit -Command ""& '$chat' chat"""
) -join ' ; '

Start-Process -FilePath 'wt' -ArgumentList "-w new $panes"
