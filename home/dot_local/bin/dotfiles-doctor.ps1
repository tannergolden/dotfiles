# --- dotfiles-doctor: check the machine really has what it claims ---
#
# The Windows twin of the extensionless bash script beside it; see that
# file for the whole argument. In short: provisioning runs from a chezmoi
# run_onchange_ script whose recorded hash means "this ran", never "this
# worked", so a machine provisioned before scoop existed has it marked
# done with nothing installed - and every later `chezmoi apply` is a
# silent no-op. The repair cannot live in an always-run chezmoi script
# either, because chezmoi reports those as permanently pending and
# `chezmoi verify` would never again exit 0.
#
#   dotfiles-doctor.ps1           install anything missing
#   dotfiles-doctor.ps1 -Check    report only, exit 1 if anything is missing

param([switch]$Check)

$ErrorActionPreference = 'Continue'

# scoop's shims may post-date the environment this process inherited, in
# which case every tool would look missing.
$shims = Join-Path $HOME 'scoop\shims'
if ((Test-Path $shims) -and ($env:PATH -notlike "*$shims*")) {
    $env:PATH = "$shims;$env:PATH"
}

# binary -> scoop package. Kept here rather than read from the manifest
# at run time, because this must work on a machine whose repository clone
# is gone - `chezmoi purge` removes it, and that is exactly a machine
# worth checking.
$verify = [ordered]@{
    'bat'       = 'bat'
    'delta'     = 'delta'
    'eza'       = 'eza'
    'fastfetch' = 'fastfetch'
    'fd'        = 'fd'
    'fzf'       = 'fzf'
    'gh'        = 'gh'
    'jq'        = 'jq'
    'ollama'    = 'ollama'
    'rg'        = 'ripgrep'
    'starship'  = 'starship'
    'zoxide'    = 'zoxide'
}

$missing = [ordered]@{}
foreach ($bin in $verify.Keys) {
    if (-not (Get-Command $bin -ErrorAction SilentlyContinue)) {
        $missing[$bin] = $verify[$bin]
    }
}

if ($missing.Count -eq 0) {
    if ($Check) { Write-Host 'ok   every expected tool is on PATH' }
    exit 0
}

if ($Check) {
    Write-Host "missing: $($missing.Keys -join ' ')"
    exit 1
}

Write-Host "==> missing from PATH: $($missing.Keys -join ' ')"

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    foreach ($pkg in $missing.Values) {
        scoop install $pkg 2>$null | Out-Null
    }
} else {
    Write-Warning '    scoop is not installed, which is why these are missing.'
    Write-Warning '    Install it from https://scoop.sh, then run this again.'
}

$still = @($missing.Keys | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) })
if ($still.Count -gt 0) {
    Write-Warning @"

  Still missing: $($still -join ' ')

  chezmoi remembers that provisioning ran, whether or not it worked.
  This forgets that and runs all of it again:

    chezmoi state delete-bucket --bucket=scriptState
    chezmoi apply

"@
    exit 1
}

Write-Host '==> toolchain repaired'
exit 0
