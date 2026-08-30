# LinuxClean

[![Shell CI](https://github.com/LceAn/LinuxClean/actions/workflows/ci.yml/badge.svg)](https://github.com/LceAn/LinuxClean/actions/workflows/ci.yml)

LinuxClean is a conservative, scriptable maintenance tool for Debian/Ubuntu-like Linux systems. It reports the machine state, previews eligible files, asks before destructive actions, and supports unattended jobs through explicit command-line options.

## Highlights

- Quick, standard, full, and custom cleanup modes.
- `--dry-run` preview with no filesystem or package changes.
- Size-sorted candidates and reclaim estimates, using a memory-bounded Top-N preview capped at 20 files by default.
- Age-based cleanup for `/tmp` and user caches (7 days by default), protecting fresh/active files.
- APT cache cleanup through `apt-get clean`.
- systemd journal vacuuming with a validated size target.
- Release-aware old-kernel detection that protects both the running kernel and the newest fallback, and groups matching image, modules, and headers packages.
- Handles root plus regular local users, or one selected user with `--user`.
- English/Chinese output, automatic locale detection, optional log file, lock, color control, and useful exit codes.
- Independent journal and kernel choices in custom mode, plus stale-lock-safe concurrency control with `flock`.

## Requirements

- Bash 4.3+ (Bash 5 recommended)
- Root privileges (`sudo` or a root shell)
- Optional tools are detected at runtime: `apt-get`, `dpkg-query`, `journalctl`, `flock`, `nproc`, and `free`.

## Usage

```bash
chmod +x LinuxClean.sh

# Interactive menu
sudo ./LinuxClean.sh

# Safe preview first
sudo ./LinuxClean.sh --mode standard --keep-days 14 --dry-run

# Show only the 10 largest file candidates
sudo ./LinuxClean.sh --mode full --dry-run --max-items 10

# Unattended daily job
sudo ./LinuxClean.sh --mode quick --yes --log-file /var/log/linuxclean.log

# Full cleanup with a larger journal retention limit
sudo ./LinuxClean.sh --mode full --journal-size 1G
```

### Options

| Option | Meaning |
| --- | --- |
| `-m, --mode MODE` | `quick`, `standard`, `full`, or `custom` |
| `-y, --yes` | Skip confirmations (use with a reviewed mode) |
| `--dry-run` | Print candidates/commands without changing anything |
| `--keep-days N` | Remove only files older than N days; default `7` |
| `--max-items N` | Show at most N file candidates in dry-run; default `20`, `0` hides item details |
| `--journal-size SIZE` | Journal target such as `100M` or `1G` |
| `--user USER` | Limit cache cleanup to one local user |
| `--language en|zh` | Override locale detection |
| `--no-color` | Disable ANSI colors |
| `--log-file FILE` | Tee plain-text output to a timestamped log file |
| `-h, --help` / `-V, --version` | Show help/version |

If stdin is not a terminal, `--mode` is required. This prevents a scheduled job from hanging at an interactive prompt.

## Safety model

LinuxClean deliberately avoids broad recursive deletion:

1. `/tmp` and `~/.cache` files are removed only when older than `--keep-days`; empty directories are removed afterwards.
2. APT is cleaned through its package-manager command rather than deleting package files directly.
3. The running kernel and newest fallback kernel are protected. Meta packages and unversioned package names are not candidates.
4. Every destructive mode prompts by default. Review `--dry-run` output before using `--yes` in automation.
5. A process lock prevents two cleanup jobs from running at the same time.

The tool does not remove documents, photos, application data, databases, or arbitrary paths outside the cleanup targets.

## Testing

Run the local smoke tests:

```bash
./test-i18n.sh
bash tests/test-unit.sh
bash -n LinuxClean.sh
```

GitHub Actions runs Bash syntax, ShellCheck, unit, CLI/i18n, and full dry-run checks. The v3.0 baseline was also checked on a Debian 11 host (`5.10.0-32-amd64`) without changing it; see `test-report.md` for the exact v3.1 validation boundary.

## License

This repository currently has no root `LICENSE` file. Treat the script as an unlicensed personal tool until a license is added; the changelog records project history.

---

## 仓库结构

- `.gitattributes`
- `.github/workflows/ci.yml`
- `CHANGELOG.md`
- `LinuxClean.sh`
- `README.md`
- `README_zh.md`
- `test-i18n.sh`
- `test-report.md`
- `tests/test-unit.sh`

<!-- repo-readme-standard:v1 -->
## 仓库维护信息

- 项目类型：产品/工具
- 当前状态：近期维护
- 可见性：public
- 维护节奏：每月只选 1-2 个小更新
- 相关仓库：无已确认的重复仓库关系；如需合并请先核对功能边界。
- 维护边界：普通文档和代码更新可直接提交；归档、删除、历史重写或强制推送需单独确认。

---

## Documentation

- [CHANGELOG.md](CHANGELOG.md) — changelog
- [ROADMAP.md](ROADMAP.md) — future plans
