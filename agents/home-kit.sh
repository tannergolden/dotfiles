#!/bin/sh
# Install the universal rules from tannergolden/intelligence into every AI app's home folder.
#
# WHY THIS EXISTS. The hub publishes one set of rules for every AI coding
# agent, and a kit around them: the guard hook, the skills and the
# subagents. This machine installs exactly one release of it,
# named in the pin file beside this script with the SHA-256 of each file
# that release serves: the home file, the kit and the installer. Nothing is
# installed, and the installer never runs, unless every pinned file matches.
# A release from before the kit pins no kit, and installs the rules alone.
# The pins change only when you run `make agents-pin` and commit the result.
#
# Run it through make:
#
#     make agents                     # install the pinned rules
#     make agents-check               # compare every copy with the pinned release
#     make agents-uninstall           # put back what was there before
#     make agents-pin VERSION=v0.1.0  # pin a release

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PIN="$HERE/intelligence.pin"
BASE="${INTELLIGENCE_BASE:-https://raw.githubusercontent.com/tannergolden/intelligence}"

say() {
  printf 'agents: %s\n' "$*" >&2
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 "$1" | cut -d ' ' -f 1
  fi
}

pinned() {
  [ -f "$PIN" ] && sed -n "s/^$1=//p" "$PIN" | head -n 1
}

download() {
  curl -fsSL --retry 2 --max-time 30 "$BASE/$1" -o "$2"
}

# A release serves its installer from home/, and one from before the hub
# moved it there, from scripts/. The pin decides either way.
fetch() {
  download "$1/home/intelligence.md" "$2/intelligence.md" \
    && { download "$1/home/install.py" "$2/install.py" 2>/dev/null \
      || download "$1/scripts/install.py" "$2/install.py"; }
}

verified() {
  version="$(pinned version)"
  if [ -z "$version" ]; then
    say "no release is pinned in $PIN yet; run make agents-pin VERSION=vX.Y.Z"
    return 1
  fi
  fetch "$version" "$1" || { say "could not download release $version"; return 1; }
  [ "$(sha256 "$1/intelligence.md")" = "$(pinned home_sha256)" ] \
    || { say "the home file of $version does not match its pin, so nothing was changed"; return 1; }
  [ "$(sha256 "$1/install.py")" = "$(pinned install_sha256)" ] \
    || { say "the installer of $version does not match its pin, so it was not run"; return 1; }
  kit="$(pinned kit_sha256)"
  [ -n "$kit" ] || return 0
  download "$version/home/kit.json" "$1/kit.json" || { say "could not download the kit of $version"; return 1; }
  [ "$(sha256 "$1/kit.json")" = "$kit" ] \
    || { say "the kit of $version does not match its pin, so nothing was changed"; return 1; }
}

# The installer's arguments for install and check: the home file, and the kit when one is pinned.
files() {
  if [ -f "$1/kit.json" ]; then
    printf '%s\n' --home-file "$1/intelligence.md" --kit-file "$1/kit.json"
  else
    printf '%s\n' --home-file "$1/intelligence.md"
  fi
}

write_pin() {
  {
    printf '# The intelligence release this machine installs, and the SHA-256 of each\n'
    printf '# file it downloads. Change it with make agents-pin VERSION=vX.Y.Z, compare\n'
    printf '# the hashes with make pins VERSION=vX.Y.Z in the hub, then commit it.\n'
    printf 'version=%s\n' "$1"
    printf 'home_sha256=%s\n' "$2"
    printf 'install_sha256=%s\n' "$3"
    printf 'kit_sha256=%s\n' "$4"
  } > "$PIN"
}

main() {
  command="${1:-}"
  for tool in curl python3; do
    command -v "$tool" >/dev/null 2>&1 || { say "$tool is not installed"; return 1; }
  done
  dir="$(mktemp -d)" || return 1
  trap 'rm -rf "$dir"' EXIT
  case "$command" in
    install | check)
      verified "$dir" || return 1
      # The paths come from mktemp and hold no spaces, so word splitting is safe.
      # shellcheck disable=SC2046
      python3 "$dir/install.py" "$command" $(files "$dir")
      ;;
    uninstall)
      verified "$dir" || return 1
      python3 "$dir/install.py" uninstall
      ;;
    pin)
      version="${2:-}"
      case "$version" in
        v[0-9]*.[0-9]*.[0-9]*) ;;
        *) say 'usage: make agents-pin VERSION=vX.Y.Z'; return 2 ;;
      esac
      fetch "$version" "$dir" || { say "could not download release $version"; return 1; }
      kit=''
      if download "$version/home/kit.json" "$dir/kit.json" 2>/dev/null; then
        kit="$(sha256 "$dir/kit.json")"
      else
        say "$version serves no kit, so only the rules are pinned"
      fi
      write_pin "$version" "$(sha256 "$dir/intelligence.md")" "$(sha256 "$dir/install.py")" "$kit"
      say "pinned $version; compare with make pins VERSION=$version in the hub, then commit $PIN"
      ;;
    *)
      say 'usage: home-kit.sh install | check | uninstall | pin vX.Y.Z'
      return 2
      ;;
  esac
}

main "$@"
