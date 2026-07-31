# --- ai-agents: which AI agent CLIs this machine actually has ---
#
# The PowerShell sibling of ~/.local/bin/ai-agents (POSIX). The roster is
# duplicated because the two shells share no language; edit both together.
#
# The roster is curated, not discovered - there is no registry of agent
# CLIs and PATH guessing would list every stray binary. Canonical binary
# names only, verified 2026-07-31. Versions are printed RAW because output
# shapes differ per tool and none are contractual.

$ErrorActionPreference = 'Continue'

$agents = @(
    @{ Bin = 'claude';       Label = 'Claude Code (Anthropic)' }
    @{ Bin = 'codex';        Label = 'Codex CLI (OpenAI)' }
    @{ Bin = 'gemini';       Label = 'Gemini CLI (Google)' }
    @{ Bin = 'agy';          Label = 'Antigravity CLI (Google)' }
    @{ Bin = 'copilot';      Label = 'Copilot CLI (GitHub)' }
    @{ Bin = 'cursor-agent'; Label = 'Cursor CLI (Anysphere)' }
    @{ Bin = 'kiro-cli';     Label = 'Kiro CLI (AWS, was Amazon Q)' }
    @{ Bin = 'aider';        Label = 'Aider' }
    @{ Bin = 'opencode';     Label = 'OpenCode (Anomaly)' }
    @{ Bin = 'crush';        Label = 'Crush (Charm)' }
    @{ Bin = 'goose';        Label = 'Goose (AAIF)' }
    @{ Bin = 'amp';          Label = 'Amp (Sourcegraph)' }
    @{ Bin = 'qwen';         Label = 'Qwen Code (Alibaba)' }
    @{ Bin = 'droid';        Label = 'Droid (Factory)' }
    @{ Bin = 'auggie';       Label = 'Auggie (Augment)' }
    @{ Bin = 'cline';        Label = 'Cline' }
    @{ Bin = 'cn';           Label = 'Continue CLI' }
    @{ Bin = 'kilo';         Label = 'Kilo Code' }
    @{ Bin = 'codebuff';     Label = 'Codebuff' }
    @{ Bin = 'kimi';         Label = 'Kimi Code (Moonshot)' }
    @{ Bin = 'grok';         Label = 'Grok Build (xAI)' }
    @{ Bin = 'iflow';        Label = 'iFlow CLI' }
    @{ Bin = 'openhands';    Label = 'OpenHands' }
    @{ Bin = 'jules';        Label = 'Jules (Google)' }
)

Write-Host 'AI agent CLIs' -ForegroundColor Blue
Write-Host ''

$found = 0
$missing = @()

foreach ($agent in $agents) {
    if (Get-Command $agent.Bin -ErrorAction SilentlyContinue) {
        $found++
        # First line only, bounded: a hung version check must not hang the
        # dashboard pane. Node CLIs take ~1s, Python up to ~3s.
        $job = Start-Job -ScriptBlock {
            param($BinName)
            (& $BinName --version 2>&1 | Select-Object -First 1)
        } -ArgumentList $agent.Bin
        $version = if (Wait-Job $job -Timeout 10) { Receive-Job $job } else { '(version check timed out)' }
        Remove-Job $job -Force
        # Same shape as the POSIX twin: version first, product second -
        # most version strings identify the tool, but "agy" alone does not.
        Write-Host "$([char]0x2713) " -ForegroundColor Green -NoNewline
        Write-Host ('{0,-14} ' -f $agent.Bin) -ForegroundColor Blue -NoNewline
        Write-Host "$version  " -NoNewline
        Write-Host $agent.Label -ForegroundColor DarkGray
    } else {
        $missing += $agent.Bin
    }
}

Write-Host ''
Write-Host ("{0} of {1} installed" -f $found, $agents.Count)
if ($missing) {
    Write-Host ("not installed: {0}" -f ($missing -join ' ')) -ForegroundColor DarkGray
}
