# --- PowerShell profile ---
#
# WHY THIS FILE IS NOT AT $PROFILE.
#
# $PROFILE lives under Documents, and OneDrive Known Folder Move can
# relocate Documents by group policy, silently, with notifications
# suppressed. chezmoi has no target-path templating (issue #2273, open),
# so a hardcoded Documents path would write to the wrong place and report
# success.
#
# Instead chezmoi owns this file at a path that never moves, and a
# provisioning script writes a one-line shim at the real, runtime-resolved
# $PROFILE that dot-sources it. Redirection can then only ever break a
# regenerable one-liner.
#
# IF THIS FILE NEVER RUNS, check the execution policy first. The default on
# Windows 10 and 11 clients is Restricted, which blocks all script files
# INCLUDING profiles. Bootstrap asks before changing it, so if you declined,
# this is why.

# --- PATH ------------------------------------------------------------------
$local:userBin = Join-Path $HOME '.local\bin'
if ((Test-Path $local:userBin) -and ($env:PATH -notlike "*$local:userBin*")) {
    $env:PATH = "$local:userBin;$env:PATH"
}

# --- environment -----------------------------------------------------------
$env:XDG_CONFIG_HOME = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
$env:XDG_CACHE_HOME  = if ($env:XDG_CACHE_HOME)  { $env:XDG_CACHE_HOME }  else { Join-Path $HOME '.cache' }
$env:XDG_DATA_HOME   = if ($env:XDG_DATA_HOME)   { $env:XDG_DATA_HOME }   else { Join-Path $HOME '.local\share' }
$env:XDG_STATE_HOME  = if ($env:XDG_STATE_HOME)  { $env:XDG_STATE_HOME }  else { Join-Path $HOME '.local\state' }

# Both read a path from the environment, which is why these two tools are
# configured identically on Windows and macOS from one file each.
$env:RIPGREP_CONFIG_PATH = Join-Path $env:XDG_CONFIG_HOME 'ripgrep\ripgreprc'
$env:BAT_CONFIG_PATH     = Join-Path $env:XDG_CONFIG_HOME 'bat\config'

# fzf reads these on Windows too, for bare `fzf` invocations. The Ctrl-T
# and Ctrl-R keybindings stay POSIX-only because fzf ships no PowerShell
# integration upstream, which the README's parity table records.
if (Get-Command fd -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
}
# Catppuccin Mocha, from catppuccin/fzf (MIT). Colours only.
#
# Byte-identical to the POSIX twin in .config/sh/env.sh, selected-bg
# included in its absence: that colour name needs fzf 0.55, and fzf
# rejects an unknown name with "invalid color specification" rather than
# ignoring it. Windows scoop fzf is current enough, but the two strings
# are kept the same so a reader comparing them finds no difference to
# explain.
$env:FZF_DEFAULT_OPTS = @(
    '--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8'
    '--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC'
    '--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8'
    '--color=border:#6C7086,label:#CDD6F4'
) -join ' '

if (Get-Command code -ErrorAction SilentlyContinue) {
    $env:EDITOR = 'code --wait'
} else {
    $env:EDITOR = 'notepad'
}
$env:VISUAL = $env:EDITOR

# --- PSReadLine ------------------------------------------------------------
# Session-only by design, which is exactly why it lives in a profile.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine

    # Default is 4096, which is small once prediction is drawing on history.
    Set-PSReadLineOption -MaximumHistoryCount 20000
    Set-PSReadLineOption -HistoryNoDuplicates:$true

    # Default is False, which leaves the cursor mid-line after a history
    # search, which is almost never what you want before pressing Enter.
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd:$true

    # Set explicitly: the cmdlet's documented parameter default and the
    # runtime default disagree, and older hosts differ again.
    try { Set-PSReadLineOption -PredictionSource HistoryAndPlugin } catch {
        try { Set-PSReadLineOption -PredictionSource History } catch { }
    }

    # The single highest value binding: type a prefix, press Up, get only
    # matching history. This is the closest equivalent to the zsh
    # history-substring search bound in .zshrc, so both shells behave alike.
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Accept one word of an inline prediction; RightArrow accepts all of it.
    # try/catch for the same reason PredictionSource has one: Windows
    # PowerShell 5.1 ships PSReadLine 2.0, which has no suggestion
    # functions at all, and an unknown -Function is a terminating error -
    # so on that host this line aborted the rest of the profile.
    try { Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptNextSuggestionWord } catch { }

    # HISTORY HYGIENE, the PowerShell half of what zsh gets from
    # HISTORY_IGNORE and hist_ignore_space. PSReadLine writes every
    # accepted line to a plain text file that lives forever, so a token
    # pasted into a command is on disk until somebody notices.
    #
    # INSTALLING THIS HANDLER REPLACES PSReadLine's OWN sensitive-line
    # screen rather than adding to it, which is why the patterns are
    # spelled out here instead of relying on the built-in: a handler that
    # only checked for a leading space would have made history hygiene
    # WORSE than the default it displaced.
    #
    # Returns a plain boolean rather than the AddToHistoryOption enum,
    # because that enum needs PSReadLine 2.2 and the boolean has worked
    # since 2.0 - this file must stay loadable under 5.1's 2.0.
    Set-PSReadLineOption -AddToHistoryHandler {
        param([string]$line)
        # A leading space keeps a command out of history, exactly as
        # hist_ignore_space does in zsh.
        if ($line -match '^\s') { return $false }
        if ($line -match '(?i)(password|passwd|token|secret|api[-_]?key|client[-_]?secret|connectionstring)') {
            return $false
        }
        return $true
    }
}

# --- aliases ---------------------------------------------------------------
# Set-Alias cannot carry arguments, so anything that takes flags has to be
# a function. This is the main reason the shell layer is duplicated rather
# than shared with zsh: there is no common syntax to share.
function g  { git @args }
function gs { git status --short --branch @args }
function gd { git diff @args }
function gl { git log --oneline --graph --decorate -20 @args }
function .. { Set-Location .. }
function ... { Set-Location ../.. }

if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ll { eza -l --git --group-directories-first @args }
    function la { eza -la --git --group-directories-first @args }
    # The zsh side has had this since the beginning; without it `tree`
    # falls through to the legacy tree.com, whose output shares nothing
    # with eza's. Remove-Item first because tree.com is an application,
    # not an alias, and a function of the same name wins only if nothing
    # shadows it.
    function tree { eza --tree @args }
} else {
    # ll and la must exist on every machine, not only where provisioning
    # finished - they are the two most typed commands in the file.
    function ll { Get-ChildItem @args }
    function la { Get-ChildItem -Force @args }
}

# --- tools -----------------------------------------------------------------
# Same tools as macOS, different init shim per shell. Note fzf ships no
# PowerShell integration at all, so its key bindings are POSIX-only.
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# --- local overrides -------------------------------------------------------
$local:localProfile = Join-Path $env:XDG_CONFIG_HOME 'powershell\profile.local.ps1'
if (Test-Path $local:localProfile) { . $local:localProfile }

# --- the dashboard opens itself --------------------------------------------
# LAST, after the local overrides, so `$env:AI_DASH_AUTO = '0'` in
# profile.local.ps1 can veto it. A machine this repository set up should
# look set up the moment a terminal opens. Every judgement call lives in
# ai-dash.ps1's auto command, not here: dashboard panes cannot recurse
# (they carry arguments; a plain interactive tab carries none), VS Code
# and ssh get the fastfetch panel inline, and the dashboard window opens
# once per boot rather than once per tab. .zshrc ends with the same
# call, so both shells open the same way. Absolute path, not PATH: the
# profile above prepends ~/.local/bin, but this must not gamble on it.
$local:aiDash = Join-Path $HOME '.local\bin\ai-dash.ps1'
if (Test-Path $local:aiDash) { & $local:aiDash auto }
