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
    Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptNextSuggestionWord
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
function ...{ Set-Location ../.. }

if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ll { eza -l --git --group-directories-first @args }
    function la { eza -la --git --group-directories-first @args }
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
