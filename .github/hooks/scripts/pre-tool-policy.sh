#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
RULES_PATH="${REPO_ROOT}/.github/hooks/policy-rules.tsv"

# The harness delivers the tool call as JSON on stdin. Argv stays supported so
# the policy can still be exercised by hand and by check-hook-policy.
#
# Argv and stdin are kept apart on purpose. The rule layer scans both, so a
# command can still be checked by hand. Only stdin is a host payload, and only a
# host payload goes to the engine: feeding argv to it as well made every hand
# invocation fail JSON parsing and get denied whenever a run existed, which meant
# this validator could not pass in the state a user is actually in - mid-run.
collect_stdin() {
  if [[ ! -t 0 ]]; then
    cat
  fi
}

ARGV_INPUT=""
if [[ "$#" -gt 0 ]]; then
  ARGV_INPUT="$*"
fi

HOST_INPUT="$(collect_stdin)"

# Joined only for the rule layer. When argv is absent the host payload must stay
# byte-identical, because the `{` check below is what routes it to the JSON path.
RAW_INPUT="${ARGV_INPUT}"
if [[ -n "${HOST_INPUT}" ]]; then
  if [[ -n "${RAW_INPUT}" ]]; then
    RAW_INPUT="${RAW_INPUT}"$'\n'"${HOST_INPUT}"
  else
    RAW_INPUT="${HOST_INPUT}"
  fi
fi

# Being on PATH is not the same as working. Windows ships a python3.exe App
# Execution Alias that is a stub which fails at runtime, so every candidate is
# probed before it is trusted.
find_usable_python() {
  local candidate
  for candidate in python3 python; do
    if command -v "${candidate}" >/dev/null 2>&1 \
      && "${candidate}" --version 2>&1 | grep -qE '^Python [0-9]+\.'; then
      command -v "${candidate}"
      return 0
    fi
  done
  return 1
}

# Only command text is scanned. A payload for an edit tool also carries the file
# content being written, and matching against that blocks any file which merely
# mentions a blocked pattern - including this repository's own documentation.
# Several key names are accepted because the harness documents toolArgs as
# provider-defined; a payload that carries none of them matches no rule, which is
# recorded as a known gap rather than turned into a blanket denial.
COMMAND_KEY='(command|commandLine|full_command_text|cmd|script)'

if [[ "${RAW_INPUT:0:1}" == "{" ]]; then
  INPUT="$(printf '%s' "${RAW_INPUT}" | grep -oP "\"${COMMAND_KEY}\"\s*:\s*\"\K(?:[^\"\\\\]|\\\\.)*" || true)"
else
  INPUT="${RAW_INPUT}"
fi

deny() {
  local reason="$1"
  local safer="$2"
  printf '{"permissionDecision":"deny","permissionDecisionReason":"%s %s"}\n' "${reason}" "${safer}"
  echo "[BLOCKED] ${reason}" >&2
  echo "Safer alternative: ${safer}" >&2
  # Exit 2 is an explicit deny for preToolUse, and denies even if stdout is ignored.
  exit 2
}

if [[ -f "${RULES_PATH}" ]]; then
  # The overwhelmingly common case is that no rule matches. Probing every rule
  # individually costs one grep process per rule - about 150ms for this file -
  # while a single combined alternation costs about 16ms. Probe once, then walk
  # the rules in file order only when something actually matched, so the first
  # matching rule still wins and its reason is still the one reported.
  COMBINED_RULES="$(grep -v '^[[:space:]]*#' "${RULES_PATH}" | grep -v '^[[:space:]]*$' | cut -f1 | paste -sd'|' - || true)"

  if [[ -z "${COMBINED_RULES}" ]] || printf '%s' "${INPUT}" | grep -Pqi -- "(?:${COMBINED_RULES})"; then
    while IFS=$'\t' read -r pattern reason safer || [[ -n "${pattern:-}" ]]; do
      if [[ -z "${pattern}" ]] || [[ "${pattern}" == \#* ]]; then
        continue
      fi

      if printf '%s' "${INPUT}" | grep -Pqi -- "${pattern}"; then
        deny "${reason}" "${safer}"
      fi
    done < "${RULES_PATH}"
  fi
else
  if echo "$INPUT" | grep -Pqi '(^|\s)rm\s+-rf(\s|$)'; then
    deny "Destructive recursive delete is blocked." "Use targeted file deletion with explicit paths and code review."
  fi

  if echo "$INPUT" | grep -Pqi '(^|\s)del\s+/s\s+/q(\s|$)'; then
    deny "Silent recursive delete is blocked." "Use Remove-Item with explicit files and -WhatIf first."
  fi

  if echo "$INPUT" | grep -Pqi 'curl\s+[^|]*\|\s*(bash|sh)'; then
    deny "Piped remote script execution is blocked." "Download script, inspect it, then run with explicit checksum verification."
  fi

  if echo "$INPUT" | grep -Pqi '(invoke-webrequest|irm|curl)\s+[^|;]*\|\s*(invoke-expression|iex)'; then
    deny "Remote content execution via Invoke-Expression is blocked." "Save remote content to a file, inspect it, and run only trusted code."
  fi

  if echo "$INPUT" | grep -Pqi '\.env.*(sk-[a-z0-9]{20,}|ghp_[a-z0-9]{20,}|akia[0-9a-z]{16}|-----begin [a-z ]*private key-----|token\s*=\s*[^\s]+)'; then
    deny "Potential real secret write to .env is blocked." "Use placeholder values and inject real secrets through secure environment management."
  fi
fi

# The engine owns stage and write-set policy. It is consulted only when a run
# exists, so ordinary editing never pays for the call and never fails on it.
#
# A gate that cannot run must not brick the editor. The rule layer above is the
# safety control and has already run; the engine gate is a governance control,
# and denying every tool call because of a missing interpreter makes the whole
# policy get switched off - which is how this guardrail died once already.

# The stage list mirrors ACTIVE_STAGES in the engine. check-hook-policy asserts
# that an active run is still gated, so a stage missing here cannot put the gate
# to sleep silently.
any_active_run() {
  local dir="$1" file stage
  for file in "${dir}"/*.json; do
    [[ -e "${file}" ]] || continue
    case "${file}" in */.tmp-*) continue ;; esac
    # The top-level stage is the only occurrence at exactly two spaces of indent;
    # the history entries that also carry a stage key sit deeper, and reading the
    # first match would report the stage a run started at rather than where it is.
    # No match means the format moved, and an unknown answer consults the engine
    # rather than assuming no run is live.
    stage="$(grep -m1 -E '^  "stage": "[a-z]+"' "${file}" | sed -E 's/.*"([a-z]+)".*/\1/' || true)"
    if [[ -z "${stage}" ]]; then
      return 0
    fi
    case "${stage}" in
      approval|implement|verify|repair|review) return 0 ;;
    esac
  done
  return 1
}

engine_gate() {
  local state_dir="${AGENTIC_STATE_DIR:-${REPO_ROOT}/.agentic/state}"
  local engine="${REPO_ROOT}/.github/scripts/agentic_engine.py"
  local python_bin engine_out engine_status

  if [[ ! -d "${state_dir}" || ! -f "${engine}" ]]; then
    return 0
  fi

  # Asking the engine costs two process spawns - the interpreter probe and the
  # engine itself - and the answer is always "allow" once no run is in an active
  # stage. Deciding that here costs a few milliseconds, so a session holding only
  # finished runs pays nothing per tool call after the rules have been checked.
  if ! any_active_run "${state_dir}"; then
    return 0
  fi

  python_bin="$(find_usable_python || true)"
  if [[ -z "${python_bin}" ]]; then
    echo "[WARN] agentic engine gate skipped: no working Python interpreter. The write-set gate is OFF; the rule layer is unaffected." >&2
    return 0
  fi

  engine_status=0
  engine_out="$(printf '%s' "${HOST_INPUT}" | "${python_bin}" "${engine}" check-tool --state-dir "${state_dir}" 2>&1)" || engine_status=$?

  if [[ "${engine_status}" -eq 0 ]]; then
    return 0
  fi
  if [[ "${engine_status}" -eq 2 && "${engine_out:0:1}" == "{" ]]; then
    printf '%s\n' "${engine_out}"
    exit 2
  fi
  echo "[WARN] agentic engine gate failed (status ${engine_status}); allowing the call. ${engine_out}" >&2
  return 0
}

engine_gate

exit 0
