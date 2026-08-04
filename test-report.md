# LinuxClean v3.1 验证报告

验证日期：2026-08-04

## v3.1 自动验证

| 项目 | 结果 | 说明 |
| --- | --- | --- |
| Bash 语法 | 通过 | `bash -n LinuxClean.sh test-i18n.sh tests/test-unit.sh` |
| ShellCheck | 通过 | ShellCheck 0.10.0，零告警 |
| 单元测试 | 通过 | 32 项检查，覆盖大小、locale、Top-N 预览、文件年龄、锁、内核分组与自定义菜单 |
| CLI / i18n | 通过 | 中英文帮助、版本、参数校验与非 root 路径 |
| source 安全 | 通过 | 加载脚本不会执行 `main` 或触发清理 |
| 锁竞争 | 回退路径通过 | 当前环境无 `flock`；CI 中将执行 `flock` 分支 |
| 残留配置边界 | 通过 | 仅匹配版本化 Linux image、headers、modules 包 |
| GitHub Actions | 已配置 | push / PR 将运行语法、ShellCheck、单元、CLI 与 full dry-run |

本轮测试在 Windows Git Bash 环境完成。测试过程中没有访问或修改系统清理目标。

## Debian 物理机基线

此前 v3.0 已在以下环境完成 quick、standard、full dry-run：

| 项目 | 配置 |
| --- | --- |
| 主机 | `192.168.2.26` |
| 操作系统 | Debian GNU/Linux 11 (bullseye) |
| 内核 | `5.10.0-32-amd64` |
| locale | `zh_CN.UTF-8` |

该基线验证过本地化系统信息、APT、root 缓存、journal、内核保护、交互退出和日志输出。本次 v3.1 验证时物理机 SSH 连续超时，因此不将旧结果标记为 v3.1 实机通过。

## 建议的复验命令

物理机恢复在线后执行：

```bash
bash -n LinuxClean.sh test-i18n.sh tests/test-unit.sh
bash tests/test-unit.sh
sudo bash test-i18n.sh
sudo bash LinuxClean.sh --mode full --yes --dry-run --no-color --max-items 5 --keep-days 14
```

所有命令均为语法、测试或 dry-run，不会执行实际清理。
