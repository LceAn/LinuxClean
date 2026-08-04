#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2034

set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../LinuxClean.sh
source "$ROOT_DIR/LinuxClean.sh"

TESTS=0

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_eq() {
    local expected="$1" actual="$2" label="$3"
    TESTS=$((TESTS + 1))
    [[ "$actual" == "$expected" ]] || fail "$label: expected '$expected', got '$actual'"
}
assert_true() {
    local label="$1"
    shift
    TESTS=$((TESTS + 1))
    "$@" || fail "$label"
}
assert_false() {
    local label="$1"
    shift
    TESTS=$((TESTS + 1))
    if "$@"; then fail "$label"; fi
}

assert_eq '104857600' "$(size_to_bytes 100M)" '100M conversion'
assert_eq '1073741824' "$(size_to_bytes 1G)" '1G conversion'
assert_eq '528482304' "$(size_to_bytes 'Archived journals take up 504.0M.')" 'journal sentence conversion'
assert_eq '1.5 KiB' "$(human_bytes 1536)" 'human byte formatting'

assert_true '100M should be a valid journal size' validate_journal_size 100M
assert_true '1GB should be a valid journal size' validate_journal_size 1GB
assert_false 'plain numbers should not be valid journal sizes' validate_journal_size 100

MODE=''
JOURNAL_LIMIT=100M
parse_args --mode FULL --journal-size 1g
assert_eq 'full' "$MODE" 'mode normalization'
assert_eq '1G' "$JOURNAL_LIMIT" 'journal size normalization'

unset LC_ALL LANGUAGE
LANG=zh_CN.UTF-8
detect_language
assert_eq 'zh' "$CURRENT_LANG" 'Chinese locale detection'
LANG=C
detect_language
assert_eq 'en' "$CURRENT_LANG" 'English locale detection'

assert_eq 'Full' "$(mode_name)" 'English mode name'

tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT
truncate -s 123 "$tmp_dir/old-file"
truncate -s 456 "$tmp_dir/new-file"
truncate -s 789 "$tmp_dir/largest-old-file"
touch -d '10 days ago' "$tmp_dir/old-file"
touch -d '10 days ago' "$tmp_dir/largest-old-file"
KEEP_DAYS=7
MAX_PREVIEW_ITEMS=0
scan_old_files "$tmp_dir" 0
assert_eq '2' "$SCAN_COUNT" 'old file count'
assert_eq '912' "$SCAN_BYTES" 'old file bytes'

MAX_PREVIEW_ITEMS=1
preview=$(scan_old_files "$tmp_dir" 1)
assert_true 'preview should retain the largest candidate only' test "${preview#*"$tmp_dir/largest-old-file"}" != "$preview"
assert_false 'preview should drop smaller candidates beyond the limit' test "${preview#*"$tmp_dir/old-file"}" != "$preview"

lock_file="$tmp_dir/linuxclean.flock"
if command -v flock >/dev/null 2>&1; then
    flock "$lock_file" -c 'sleep 1' &
    lock_holder=$!
    sleep 0.1
    TESTS=$((TESTS + 1))
    if (DRY_RUN=0; LOCK_FILE="$lock_file"; setup_lock) >/dev/null 2>&1; then
        fail 'flock contention should reject a second process'
    fi
    wait "$lock_holder"
else
    mkdir "${lock_file}.d"
    TESTS=$((TESTS + 1))
    if (DRY_RUN=0; LOCK_FILE="$lock_file"; setup_lock) >/dev/null 2>&1; then
        fail 'fallback lock contention should reject a second process'
    fi
    rmdir "${lock_file}.d"
fi

assert_eq '6.1.0-20-amd64' "$(kernel_release_from_image_package linux-image-6.1.0-20-amd64)" 'signed image release'
assert_eq '6.8.0-52-generic' "$(kernel_release_from_image_package linux-image-unsigned-6.8.0-52-generic)" 'unsigned image release'
assert_false 'kernel metapackage must not produce a release' kernel_release_from_image_package linux-image-amd64

mapfile -t kernels < <(
    sorted_nonrunning_kernel_releases '6.1.0-20-amd64' \
        6.1.0-20-amd64 \
        6.1.0-18-amd64 \
        6.1.0-21-amd64 \
        6.1.0-19-amd64
)
assert_eq '3' "${#kernels[@]}" 'non-running kernel count'
assert_eq '6.1.0-18-amd64' "${kernels[0]}" 'kernel version sort start'
assert_eq '6.1.0-21-amd64' "${kernels[2]}" 'kernel version sort end'

mapfile -t kernel_packages < <(
    printf '%s\n' \
        linux-image-6.1.0-18-amd64 \
        linux-headers-6.1.0-18-amd64 \
        linux-modules-6.1.0-18-amd64 \
        linux-modules-extra-6.1.0-18-amd64 \
        linux-image-6.1.0-20-amd64 \
        linux-image-amd64 |
        filter_kernel_packages_for_releases 6.1.0-18-amd64
)
assert_eq '4' "${#kernel_packages[@]}" 'kernel release package group count'
assert_eq 'linux-modules-extra-6.1.0-18-amd64' "${kernel_packages[3]}" 'kernel release package group end'

mapfile -t residual < <(
    printf '%s\n' \
        $'linux-image-6.1.0-10-amd64\tdeinstall ok config-files' \
        $'linux-headers-6.1.0-10-common\tdeinstall ok config-files' \
        $'linux-image-amd64\tdeinstall ok config-files' \
        $'nginx\tdeinstall ok config-files' \
        $'linux-image-6.1.0-20-amd64\tinstall ok installed' |
        filter_residual_kernel_packages
)
assert_eq '2' "${#residual[@]}" 'residual kernel filter count'
assert_eq 'linux-image-6.1.0-10-amd64' "${residual[0]}" 'residual image filter'
assert_eq 'linux-headers-6.1.0-10-common' "${residual[1]}" 'residual headers filter'

CUSTOM_JOURNAL=0
CUSTOM_KERNEL=0
clean_journal() { CUSTOM_JOURNAL=$((CUSTOM_JOURNAL + 1)); }
clean_old_kernels() { CUSTOM_KERNEL=$((CUSTOM_KERNEL + 1)); }
run_custom <<< $'4\n0' >/dev/null
assert_eq '1' "$CUSTOM_JOURNAL" 'custom journal selection'
assert_eq '0' "$CUSTOM_KERNEL" 'custom journal must not run kernel cleanup'
run_custom <<< $'5\n0' >/dev/null
assert_eq '1' "$CUSTOM_KERNEL" 'custom kernel selection'

DRY_RUN=1
assert_true 'dry-run confirmations should be automatic' confirm

printf 'PASS: %d unit checks\n' "$TESTS"
