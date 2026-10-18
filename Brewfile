# ==============================================================================
#
#   B R E W F I L E                what this suite needs from homebrew
#   (c) ALIEN DYNAMICS 1984  ·  read by scripts/bootstrap.zsh --tools
#
#   Short on purpose.  These are the packages the machines in this repo
#   actually reach for -- not a copy of somebody's machine.  Everything
#   else a Mac needs, it already has: zsh, curl, perl, sysctl, vm_stat,
#   top, ioreg, pmset, netstat, osascript, afplay and pbcopy all ship.
#
#     brew bundle --file Brewfile        what the installer runs
#     brew bundle check --file Brewfile  what is missing, without installing
#
# ==============================================================================

# ── the local model side ─────────────────────────────────────────────────────
# INTELLIGENCE's LOCAL page pulls models through ollama and loads them into
# it; its CONSOLE and its REWRITE page talk to whatever runner is up on
# 127.0.0.1.  ollama holds a model in memory and answers on :11434;
# llama.cpp is the other way to do the same thing, one server per GGUF, on
# :8080.  The cabinet says plainly when they are absent, but the LOCAL page
# can do nothing without one of them.  The installer also registers ollama
# with `brew services`, so the runner is up on every login and a model can
# be pulled the moment the cabinet is.
brew "ollama"
brew "llama.cpp"

# ── the agent that runs the local models ────────────────────────────────────
# OpenCode takes any OpenAI-shaped endpoint as a provider, which is what a
# runner on this machine is.  ⏎ on a model on INTELLIGENCE's LOCAL page
# opens OpenCode in the glass with that model -- so a pulled model is a
# coding agent, not a chat.  The other four agents sign in on their own
# account and are installed from INTELLIGENCE's CLOUD page, one at a time.
brew "opencode"

# ── what an agent's own installer needs ──────────────────────────────────────
# CODEX installs with `npm install -g @openai/codex`, which needs a node.  The
# other agents fetch their own binary and do not.
brew "node"
