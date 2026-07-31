# --- zsh plugins: the two that earn their startup cost ---
#
# WHY A FILE AND NOT A PLUGIN MANAGER. Both of these are plain packages
# in the manifest - a brew formula on macOS, an apt package on Debian and
# in a codespace - and loading them is one guarded `source` each. A plugin
# manager would add a dependency, a lockfile, a cache and a self-update
# path to do what six lines do here, and would own the thing it is
# hardest to debug: the order widgets wrap each other.
#
# WHAT THEY BUY, and why the parity ledger demanded them. PowerShell has
# had both since the profile was written: PSReadLine gives inline history
# prediction (PredictionSource) and colours the command line as you type.
# zsh had neither, so the two shells this repository claims are equivalent
# were not, in the direction nobody expects.
#
# EVERY PATH IS PROBED, NOTHING IS ASSUMED. First readable wins:
#   /opt/homebrew/...  Apple Silicon brew
#   /usr/local/...     Intel brew
#   /usr/share/...     Debian and Ubuntu apt
# A machine missing the package gets a working shell and no error, which
# is the same contract every other tool in .zshrc has.

# --- autosuggestions -------------------------------------------------------
# Suggests the rest of the line from history, in a dim colour, accepted
# with the right arrow. The default highlight (fg=8) is deliberately kept
# rather than set to a Mocha hex: zsh renders hex styles only on a
# truecolor terminal or via zsh/nearcolor, and Terminal.app - the macOS
# terminal this repository configures - supports neither, where fg=8
# resolves to the palette's own muted tone on every terminal here.
for _p in /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
          /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
          /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -r "${_p}" ]] && source "${_p}" && break
done

# --- syntax highlighting ---------------------------------------------------
# MUST BE THE LAST THING SOURCED IN THE WHOLE STARTUP. It wraps every ZLE
# widget that exists at the moment it loads, so anything defining widgets
# afterwards - including the fzf keybindings above and autosuggestions
# itself - is simply not highlighted. Upstream states this requirement
# outright, and it is why this file is sourced at the very end of .zshrc
# rather than beside the other tools.
for _p in /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
          /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
          /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r "${_p}" ]] && source "${_p}" && break
done

unset _p
