# LinuxClean

[![Shell CI](https://github.com/LceAn/LinuxClean/actions/workflows/ci.yml/badge.svg)](https://github.com/LceAn/LinuxClean/actions/workflows/ci.yml)

LinuxClean 是一个面向 Debian/Ubuntu 类 Linux 的保守型系统维护工具。它会先展示系统状态，默认在执行删除前确认，并通过命令行参数支持可审计的自动化任务。

## 主要能力

- 快速、标准、完全、自定义四种清理模式。
- `--dry-run` 演练模式：只展示候选文件和命令，不修改系统。
- 候选文件按大小排序并显示预计释放量，使用固定容量 Top-N 缓冲区，默认只展示最大的 20 项。
- `/tmp` 和用户缓存按文件年龄清理（默认超过 7 天），避免误删新文件或活跃文件。
- 通过 `apt-get clean` 清理 APT 缓存。
- 使用 systemd journal 的 vacuum 功能并校验保留大小。
- 按 release 识别旧内核，同时保护当前运行内核和最新备用内核，并成组处理对应的 image、modules 与 headers 包。
- 默认处理 root 和普通本地用户，也可通过 `--user` 指定一个用户。
- 中英文输出、自动语言检测、日志文件、进程锁和无色输出支持。
- 自定义模式可分别选择 journal 与内核清理，并通过 `flock` 避免异常退出留下僵尸锁。

## 环境要求

- Bash 4.3+（推荐 Bash 5）
- root 权限（`sudo` 或 root shell）
- 可选命令会在运行时检测：`apt-get`、`dpkg-query`、`journalctl`、`flock`、`nproc`、`free`。

## 使用方法

```bash
chmod +x LinuxClean.sh

# 交互式菜单
sudo ./LinuxClean.sh

# 先做无损预览
sudo ./LinuxClean.sh --mode standard --keep-days 14 --dry-run

# 预览时仅展示最大的 10 个候选文件
sudo ./LinuxClean.sh --mode full --dry-run --max-items 10

# 自动任务（无需交互确认）
sudo ./LinuxClean.sh --mode quick --yes --log-file /var/log/linuxclean.log

# 完全清理，并将日志保留到 1G
sudo ./LinuxClean.sh --mode full --journal-size 1G
```

### 参数

| 参数 | 说明 |
| --- | --- |
| `-m, --mode MODE` | `quick`、`standard`、`full` 或 `custom` |
| `-y, --yes` | 跳过确认（建议只用于已审阅的模式） |
| `--dry-run` | 打印候选项和命令，不执行修改 |
| `--keep-days N` | 只删除超过 N 天的文件，默认 `7` |
| `--max-items N` | dry-run 最多展示 N 个文件候选，默认 `20`；`0` 表示不逐项展示 |
| `--journal-size SIZE` | 日志目标，例如 `100M`、`1G` |
| `--user USER` | 只清理指定用户的缓存 |
| `--language en\|zh` | 覆盖系统语言检测 |
| `--no-color` | 禁用 ANSI 颜色 |
| `--log-file FILE` | 将纯文本输出同时写入带时间戳的日志文件 |
| `-h, --help` / `-V, --version` | 显示帮助/版本 |

当标准输入不是终端时必须指定 `--mode`，这样定时任务不会卡在交互提示上。

## 安全策略

LinuxClean 不使用无条件的递归删除：

1. `/tmp` 和 `~/.cache` 只删除超过 `--keep-days` 的文件，然后删除空目录。
2. APT 通过包管理器命令清理，不直接删除包文件。
3. 永远保护当前运行内核和最新备用内核；元包和未带版本号的包不会成为候选。
4. 默认每个破坏性模式都需要确认。自动化前请先检查 `--dry-run` 输出。
5. 使用进程锁防止两个清理任务同时运行。

工具不会删除文档、照片、应用数据、数据库或清理目标以外的任意路径。

## 测试

```bash
./test-i18n.sh
bash tests/test-unit.sh
bash -n LinuxClean.sh
```

GitHub Actions 会运行 Bash 语法、ShellCheck、单元、CLI/i18n 和完整 dry-run 检查。v3.0 基线也曾在 Debian 11（`5.10.0-32-amd64`）上完成无修改验证；v3.1 的准确验证边界见 `test-report.md`。

## 许可证

项目历史请参阅仓库中的许可证和更新日志。
