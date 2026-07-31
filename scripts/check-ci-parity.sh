#!/usr/bin/env bash
# --- Prove that `make lint` and the pipeline are the same set of checks ---
#
# THE CLAIM THIS DEFENDS. The README tells a contributor that "make lint
# and make test run what continuous integration runs, so a green local
# run means a green pipeline". That was true by inspection and by nothing
# else: the workflow lists the lint prerequisites as SEPARATE steps, for
# per-check granularity in the Actions UI, so the equivalence was
# maintained by two files agreeing about a list.
#
# The failure mode is silent and one-directional, which is the bad
# direction: add a prerequisite to `lint` and forget the workflow, and
# the new check runs for you locally, passes, and never gates a pull
# request again. Nothing turns red. It happened during the change that
# added this script - a fifth prerequisite - which is why the script
# exists rather than a comment asking people to remember.
#
# WHAT IT DOES NOT CHECK, stated so a pass is not overread: that the
# steps do the same thing, only that every prerequisite of `lint` is
# invoked somewhere in the workflow. A step that runs the target with
# different arguments would still pass.
#
# BASH 3.2 ONLY.

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MAKEFILE="${REPO_DIR}/Makefile"
WORKFLOW="${REPO_DIR}/.github/workflows/bootstrap.yaml"

[ -f "${MAKEFILE}" ] || { echo "FAIL no Makefile at ${MAKEFILE}" >&2; exit 1; }
[ -f "${WORKFLOW}" ] || { echo "FAIL no workflow at ${WORKFLOW}" >&2; exit 1; }

# The prerequisites of `lint`, with the ## help text stripped. Anchored to
# a line starting `lint:` so `lint-shell:` and friends do not match.
PREREQS="$(sed -n 's/^lint:[[:space:]]*\(.*\)/\1/p' "${MAKEFILE}" | sed 's/#.*//')"

if [ -z "${PREREQS}" ]; then
  echo "FAIL could not read the prerequisites of the 'lint' target" >&2
  exit 1
fi

missing=0
checked=0
for target in ${PREREQS}; do
  checked=$((checked + 1))
  # `make <target>` anywhere in the workflow counts as mirrored.
  if ! grep -qE "make[[:space:]]+${target}([[:space:]]|$)" "${WORKFLOW}"; then
    echo "FAIL 'make ${target}' is a prerequisite of 'make lint' but never runs in $(basename "${WORKFLOW}")"
    missing=$((missing + 1))
  fi
done

if [ "${checked}" -eq 0 ]; then
  echo "FAIL parsed the lint target but found no prerequisites; this check examined nothing" >&2
  exit 1
fi

if [ "${missing}" -eq 0 ]; then
  echo "ok   all ${checked} 'make lint' check(s) also run in CI"
  exit 0
fi

cat >&2 <<EOF

The pipeline no longer runs everything 'make lint' runs, so a green local
run would stop meaning a green pipeline. Add the missing step to
.github/workflows/bootstrap.yaml, in the lint job.
EOF
exit 1
