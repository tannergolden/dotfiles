# --- ai-model: the strongest local model this machine can actually hold ---
#
# The PowerShell sibling of ~/.local/bin/ai-model (POSIX). Same ladder,
# same subcommands, same environment knobs; only the detection plumbing is
# Windows-shaped. The two files must be edited together - the ladder is
# duplicated because there is no language the two shells share.
#
# WINDOWS-SPECIFIC FACTS THE DETECTION LEANS ON, verified 2026-07-31:
#   * RAM comes from Win32_ComputerSystem.TotalPhysicalMemory via CIM.
#     wmic is not used: deprecated, disabled by default in 24H2, removed
#     in 25H2.
#   * Win32_VideoController.AdapterRAM is a uint32 and therefore CANNOT
#     report more than 4GB - every modern GPU misreports through it. The
#     64-bit truth lives in the registry as HardwareInformation.
#     qwMemorySize under the display-adapter class key, so that is read
#     instead, with nvidia-smi preferred when present (also found in
#     DriverStore, where modern drivers hide it off PATH).
#   * The Ollama Windows APP auto-starts its server when any CLI command
#     needs it; the scoop CLI-only package does not, so the server is
#     started here when it is not answering - same as the POSIX script
#     does on Linux and for the brew formula.

param(
    [Parameter(Position = 0)]
    [ValidateSet('status', 'install', 'chat', 'help')]
    [string]$Command = 'status',

    [switch]$Auto
)

$ErrorActionPreference = 'Stop'

# --- the ladder ------------------------------------------------------------
# Keep in lockstep with executable_ai-model. Columns: minimum budget GiB,
# ollama tag, download GB (default quant, rounded up). Same traps apply:
# gemma4:latest is the (bigger!) edge model, qwen3-next needs the explicit
# thinking tag, cloud-only tags have no local weights.
$script:Ladder = @(
    @{ Min = 115; Tag = 'qwen3.5:122b-a10b';           Gb = 81 }
    @{ Min = 90;  Tag = 'gpt-oss:120b';                Gb = 65 }
    @{ Min = 64;  Tag = 'qwen3-next:80b-a3b-thinking'; Gb = 50 }
    @{ Min = 44;  Tag = 'qwen3.6:35b';                 Gb = 24 }
    @{ Min = 28;  Tag = 'glm-4.7-flash';               Gb = 19 }
    @{ Min = 20;  Tag = 'gpt-oss:20b';                 Gb = 14 }
    @{ Min = 12;  Tag = 'gemma4:12b';                  Gb = 8 }
    @{ Min = 9;   Tag = 'qwen3.5:9b';                  Gb = 7 }
    @{ Min = 6;   Tag = 'qwen3.5:4b';                  Gb = 4 }
    @{ Min = 4;   Tag = 'qwen3:4b';                    Gb = 3 }
    @{ Min = 0;   Tag = 'qwen3:0.6b';                  Gb = 1 }
)

$script:AutoMaxGb = if ($env:AI_MODEL_AUTO_MAX_GB) { [int]$env:AI_MODEL_AUTO_MAX_GB } else { 32 }

$script:StateDir = if ($env:XDG_STATE_HOME) { Join-Path $env:XDG_STATE_HOME 'ai-dash' }
                   else { Join-Path $HOME '.local\state\ai-dash' }
$script:StateFile = Join-Path $script:StateDir 'model'

function Write-Step($Message) { Write-Host "==> $Message" -ForegroundColor Blue }
function Write-Note($Message) { Write-Warning $Message }

# --- hardware detection ----------------------------------------------------
function Find-NvidiaSmi {
    $cmd = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    # Modern drivers put it in DriverStore, older ones under Program Files;
    # neither is on PATH.
    $candidates = @(
        Join-Path $env:SystemRoot 'System32\nvidia-smi.exe'
        Join-Path $env:ProgramFiles 'NVIDIA Corporation\NVSMI\nvidia-smi.exe'
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    $store = Get-ChildItem -Path (Join-Path $env:SystemRoot 'System32\DriverStore\FileRepository\nvdm*\nvidia-smi.exe') `
        -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($store) { return $store.FullName }
    return $null
}

function Get-Budget {
    # Returns @{ Kind; Gb }.
    $ramBytes = [uint64](Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory

    # Windows-on-ARM is unified memory, so it budgets like Apple Silicon's
    # conservative fraction rather than like a dGPU machine.
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
        return @{ Kind = 'arm64-unified'; Gb = [int]($ramBytes / 1GB * 3 / 4) }
    }

    $smi = Find-NvidiaSmi
    if ($smi) {
        $lines = & $smi '--query-gpu=memory.total' '--format=csv,noheader,nounits' 2>$null
        if ($LASTEXITCODE -eq 0 -and $lines) {
            # Largest single card, not the sum: one model cannot run at
            # full speed across mismatched GPUs.
            $mib = ($lines | ForEach-Object { [int]($_ -replace '[^0-9]', '') } |
                Measure-Object -Maximum).Maximum
            if ($mib -gt 0) { return @{ Kind = 'nvidia'; Gb = [int]($mib / 1024) } }
        }
    }

    # 64-bit registry value the display driver writes; the WMI AdapterRAM
    # path is knowingly skipped (uint32, truncates at 4GB).
    $classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0*'
    $qw = Get-ItemProperty -Path $classKey -Name 'HardwareInformation.qwMemorySize' `
        -ErrorAction SilentlyContinue
    if ($qw) {
        $vramBytes = ($qw.'HardwareInformation.qwMemorySize' | Measure-Object -Maximum).Maximum
        # Same 4GiB floor as the POSIX script: below that it is an iGPU
        # carve-out and the machine budgets as CPU-only.
        if ($vramBytes -ge 4GB) {
            return @{ Kind = 'gpu'; Gb = [int]($vramBytes / 1GB) }
        }
    }

    return @{ Kind = 'cpu'; Gb = [int]($ramBytes / 1GB * 3 / 4) }
}

# --- ladder lookup ---------------------------------------------------------
function Select-Tier([int]$BudgetGb, [int]$MaxGb) {
    foreach ($tier in $script:Ladder) {
        if ($BudgetGb -lt $tier.Min) { continue }
        if ($MaxGb -gt 0 -and $tier.Gb -gt $MaxGb) { continue }
        return $tier
    }
    return $null
}

# --- ollama plumbing -------------------------------------------------------
function Test-Server {
    & ollama ps 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Confirm-Server {
    if (Test-Server) { return }
    New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null
    $log = Join-Path $script:StateDir 'ollama-serve.log'
    Write-Step "starting ollama serve (log: $log)"
    Start-Process -FilePath 'ollama' -ArgumentList 'serve' -WindowStyle Hidden `
        -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    foreach ($i in 1..40) {
        if (Test-Server) { return }
        Start-Sleep -Milliseconds 500
    }
    throw "ollama server did not come up; see $log"
}

function Get-Normalised($Tag) {
    if ($Tag -match ':') { return $Tag }
    return "${Tag}:latest"
}

function Get-InstalledTags {
    $out = & ollama list 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) { return @() }
    return @($out | Select-Object -Skip 1 | ForEach-Object { ($_ -split '\s+')[0] })
}

function Test-ModelInstalled($Tag) {
    return (Get-InstalledTags) -contains (Get-Normalised $Tag)
}

function Get-BestInstalled {
    $have = Get-InstalledTags
    if (-not $have) { return $null }
    foreach ($tier in $script:Ladder) {
        if ($have -contains (Get-Normalised $tier.Tag)) { return $tier.Tag }
    }
    return $have[0]
}

# --- disk preflight --------------------------------------------------------
# Ollama preallocates and fails mid-pull with no free-space check of its
# own, so the check lives here: download size plus 20% headroom.
function Test-DiskOk([int]$SizeGb) {
    $dir = if ($env:OLLAMA_MODELS) { $env:OLLAMA_MODELS } else { Join-Path $HOME '.ollama\models' }
    $root = [System.IO.Path]::GetPathRoot($dir)
    try {
        $free = ([System.IO.DriveInfo]::new($root)).AvailableFreeSpace
    } catch {
        Write-Note "could not determine free space for $dir; continuing"
        return $true
    }
    $need = [uint64]$SizeGb * 1GB * 12 / 10
    if ($free -lt $need) {
        Write-Note ("need ~{0}GB free for a {1}GB model; only {2}GB available on {3}" -f `
            [int]($need / 1GB), $SizeGb, [int]($free / 1GB), $root)
        return $false
    }
    return $true
}

# --- subcommands -----------------------------------------------------------
function Invoke-Install {
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        throw "ollama is not installed; run 'chezmoi apply'"
    }

    $budget = Get-Budget
    $tag = $null
    $sizeGb = 0

    if ($env:AI_MODEL) {
        $tag = $env:AI_MODEL
        Write-Step "AI_MODEL=$tag overrides the ladder"
    } else {
        if ($budget.Gb -le 0) { throw 'could not detect usable memory' }
        $cap = if ($Auto) { $script:AutoMaxGb } else { 0 }
        if ($env:AI_MODEL_MAX_GB) {
            $userCap = [int]$env:AI_MODEL_MAX_GB
            if ($cap -eq 0 -or $userCap -lt $cap) { $cap = $userCap }
        }
        $tier = Select-Tier $budget.Gb $cap
        if (-not $tier) { throw "no model fits a $($budget.Gb)GB budget under a ${cap}GB cap" }
        $tag = $tier.Tag
        $sizeGb = $tier.Gb
        Write-Step "detected $($budget.Kind), usable model memory ~$($budget.Gb)GB -> $tag (~${sizeGb}GB download)"
        if ($cap -gt 0) {
            $full = Select-Tier $budget.Gb 0
            if ($full -and $full.Tag -ne $tag) {
                Write-Step "this machine could hold $($full.Tag) (~$($full.Gb)GB); run 'ai-model install' by hand to pull it"
            }
        }
    }

    Confirm-Server

    if (Test-ModelInstalled $tag) {
        Write-Step "$tag is already installed"
    } else {
        if ($sizeGb -gt 0 -and -not (Test-DiskOk $sizeGb)) {
            throw "not enough disk for $tag; free some space or set OLLAMA_MODELS to a bigger volume"
        }
        Write-Step "pulling $tag (interrupted pulls resume; re-run to continue)"
        & ollama pull $tag
        if ($LASTEXITCODE -ne 0) { throw "pull failed for $tag" }
    }

    New-Item -ItemType Directory -Path $script:StateDir -Force | Out-Null
    Set-Content -Path $script:StateFile -Value $tag
    Write-Step "default model recorded in $script:StateFile"
}

function Invoke-Chat {
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Note 'ollama is not installed, so there is no local model to chat with'
        Write-Host "Install it (chezmoi apply installs it), then run: ai-model install"
        return
    }
    Confirm-Server
    $tag = $null
    if ($env:AI_MODEL) { $tag = $env:AI_MODEL }
    elseif (Test-Path $script:StateFile) { $tag = (Get-Content $script:StateFile -First 1) }
    if ($tag -and -not (Test-ModelInstalled $tag)) {
        Write-Note "$tag is not installed; falling back to the best installed model"
        $tag = $null
    }
    if (-not $tag) { $tag = Get-BestInstalled }
    if (-not $tag) {
        Write-Note 'no local model installed yet'
        Write-Host 'Run: ai-model install'
        return
    }
    Write-Step "chatting with $tag (exit with /bye or Ctrl+D)"
    & ollama run $tag
}

function Invoke-Status {
    $budget = Get-Budget
    Write-Host ("hardware        {0}" -f $budget.Kind)
    Write-Host ("model budget    ~{0}GB" -f $budget.Gb)
    $tier = Select-Tier $budget.Gb 0
    if ($tier) {
        Write-Host ("ladder choice   {0} (~{1}GB download)" -f $tier.Tag, $tier.Gb)
    } else {
        Write-Host 'ladder choice   none'
    }
    if (Test-Path $script:StateFile) {
        Write-Host ("default model   {0}" -f (Get-Content $script:StateFile -First 1))
    } else {
        Write-Host 'default model   not set (run: ai-model install)'
    }
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Write-Host 'ollama          not installed'
    } elseif (-not (Test-Server)) {
        Write-Host 'ollama          installed, server not running'
    } else {
        Write-Host 'ollama          serving'
        & ollama list 2>$null | Select-Object -Skip 1 | ForEach-Object {
            $f = $_ -split '\s+'
            Write-Host ("  installed     {0}  {1} {2}" -f $f[0], $f[2], $f[3])
        }
    }
}

function Show-Usage {
    Write-Host @'
usage: ai-model [status|install [-Auto]|chat]

  status    Show detected hardware, the ladder's choice, and what is installed
  install   Pick the strongest model that fits and pull it
            -Auto   cap the download at AI_MODEL_AUTO_MAX_GB (default 32)
                    for unattended runs
  chat      Interactive chat with the default model (the dashboard pane)

environment:
  AI_MODEL              force a specific ollama tag, skipping the ladder
  AI_MODEL_MAX_GB       cap the download size the ladder may choose
  AI_MODEL_AUTO_MAX_GB  the -Auto cap (default 32)
  OLLAMA_MODELS         where models are stored (also where disk is checked)
'@
}

switch ($Command) {
    'status'  { Invoke-Status }
    'install' { Invoke-Install }
    'chat'    { Invoke-Chat }
    'help'    { Show-Usage }
}
