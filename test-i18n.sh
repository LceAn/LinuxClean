#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/LinuxClean.sh"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
contains() {
    local haystack="$1" needle="$2"
    [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

[[ -r "$SCRIPT" ]] || fail "LinuxClean.sh not found"
bash -n "$SCRIPT" || fail "LinuxClean.sh has a syntax error"

english_help=$(LC_ALL=C LANG=C bash "$SCRIPT" --help)
contains "$english_help" 'Usage'
contains "$english_help" '--dry-run'
contains "$english_help" '--max-items'
contains "$english_help" 'quick, standard, full, or custom'

chinese_help=$(LC_ALL=C LANG=C bash "$SCRIPT" --language zh --help)
contains "$chinese_help" '用法'
contains "$chinese_help" '模式：quick、standard、full、custom'

version=$(LC_ALL=C LANG=C bash "$SCRIPT" --version)
contains "$version" 'LinuxClean 3.1'

if LC_ALL=C LANG=C bash "$SCRIPT" --definitely-invalid >/dev/null 2>&1; then
    fail 'invalid options should return a non-zero status'
fi

if LC_ALL=C LANG=C bash "$SCRIPT" --max-items nope --mode quick --dry-run >/dev/null 2>&1; then
    fail 'invalid --max-items values should return a non-zero status'
fi

if LC_ALL=C LANG=C bash "$SCRIPT" --language invalid --mode quick --dry-run >/dev/null 2>&1; then
    fail 'invalid --language values should return a non-zero status'
fi

if ((EUID == 0)); then
    preview=$(LC_ALL=C LANG=C bash "$SCRIPT" --mode quick --yes --dry-run --no-color --max-items 1)
    contains "$preview" 'Cleanup plan:'
    contains "$preview" 'Preview completed; no changes were made'
    contains "$preview" 'Estimated reclaimable space:'
    if LC_ALL=C LANG=C bash "$SCRIPT" --mode standard --dry-run --user __linuxclean_missing_user__ >/dev/null 2>&1; then
        fail 'unknown --user values should return a non-zero status'
    fi
    if LC_ALL=C LANG=C bash "$SCRIPT" --mode custom --dry-run </dev/null >/dev/null 2>&1; then
        fail 'custom mode should require an interactive terminal'
    fi
fi

printf 'PASS: syntax, i18n, options, validation, and root dry-run checks\n'
