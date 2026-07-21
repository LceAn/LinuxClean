# LinuxClean v3.0 验证报告

验证日期：2026-07-21
验证主机：Debian GNU/Linux 11（`192.168.2.26`，内核 `5.10.0-32-amd64`）

## 验证项目

| 项目 | 结果 | 说明 |
| --- | --- | --- |
| Bash 语法 | 通过 | `bash -n LinuxClean.sh` |
| 帮助/版本 | 通过 | `--help`、`--version` 返回成功 |
| 国际化 | 通过 | English 与中文帮助文本均可输出 |
| 参数校验 | 通过 | 非法选项和日志大小返回非零状态 |
| 候选预览 | 通过 | 按大小排序，默认最多展示 20 项并显示省略数量 |
| 空间估算 | 通过 | 分阶段统计并输出 dry-run 预计释放总量 |
| quick dry-run | 通过 | 预览 `/tmp` 与 APT，未修改主机 |
| standard dry-run | 通过 | 预览用户缓存和 systemd journal |
| full dry-run | 通过 | 识别 2 个已安装内核，保护运行中及唯一备用内核 |
| 非交互入口 | 通过 | 指定 `--mode` 后不会等待 `read` 输入 |

## 结果摘要

- 远端系统使用中文 locale（`zh_CN.UTF-8`）时，`free`/`df` 的本地化表头不会影响系统信息解析。
- dry-run 会按大小列出超过保留天数的候选文件，并以 `+ command` 形式展示不会执行的包管理器/日志命令。
- full dry-run 统计约 1.7 GiB 可释放空间：APT 约 1.2 GiB、journal 约 404 MiB、root 缓存约 94 MiB，以及少量 `/tmp` 文件。
- journal 以统一的人类可读大小显示，不再混入英文原始句子；dry-run 使用专用“预览完成”汇总。
- 本次验证没有执行实际删除、APT 清理、journal vacuum 或内核卸载。

## 建议的生产操作

先在目标主机上执行：

```bash
sudo ./LinuxClean.sh --mode full --keep-days 14 --dry-run
```

检查输出无误后，再使用合适的模式和 `--yes`。自动任务建议保留 `--log-file`，并从 quick/standard 模式开始。
