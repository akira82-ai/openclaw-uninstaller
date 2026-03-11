# OpenClaw Uninstaller

一键卸载 OpenClaw 的跨平台工具，让这只龙虾体面告别 🦞

## 简介

OpenClaw Uninstaller 是一个功能强大且安全的卸载工具，可以帮助你从系统中完全移除 OpenClaw 软件的所有组件，包括 CLI 工具、系统服务、状态目录、配置文件和桌面应用。

## 功能特性

- **跨平台支持**：支持 macOS、Linux 和 Windows 系统
- **智能检测**：自动检测系统中所有 OpenClaw 组件
- **彻底清理**：清理所有残留文件、配置和缓存
- **安全卸载**：包含用户确认机制，防止误操作
- **友好界面**：彩色输出和清晰的进度提示
- **容错设计**：即使部分组件卸载失败也能继续执行

## 支持的平台

| 平台 | 支持情况 | 特殊功能 |
|------|---------|---------|
| macOS | ✅ 完全支持 | 包含桌面应用卸载 |
| Linux | ✅ 完全支持 | systemd 服务管理 |
| Windows | ✅ 完全支持 | PowerShell 脚本 |

## 快速开始

### macOS / Linux

```bash
# 下载并赋予执行权限
chmod +x uninstall.sh

# 运行卸载脚本
./uninstall.sh
```

### Windows

**方法一：双击批处理文件**
```
双击 uninstall.bat
```

**方法二：使用 PowerShell**
```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

## 卸载内容说明

脚本会自动检测并清理以下内容：

### 通用组件
- **CLI 工具**：通过 npm/pnpm/bun 全局安装的命令行工具
- **系统服务**：
  - macOS: launchd 服务 (ai.openclaw.gateway)
  - Linux: systemd 用户服务 (openclaw-gateway.service)
  - Windows: 系统服务
- **状态目录**：~/.openclaw 及相关目录
- **工作空间**：~/.openclaw/workspace
- **配置文件**：.openclawrc、.openclaw.config 等

### macOS 专属
- **桌面应用**：/Applications/OpenClaw.app
- **应用支持文件**：Library/Application Support、Caches、Preferences、Logs

### Linux 专属
- **systemd 配置**：~/.config/systemd/user/openclaw-gateway.service

### Windows 专属
- **注册表项**：相关服务注册信息
- **AppData 文件**：%APPDATA%、%LOCALAPPDATA% 下的 openclaw 目录

## 卸载流程

1. **环境检测**：识别操作系统和已安装的 OpenClaw 组件
2. **显示摘要**：列出所有将要删除的组件和文件
3. **用户确认**：请求用户确认是否继续卸载
4. **停止服务**：停止所有运行中的 OpenClaw 服务
5. **卸载服务**：删除系统服务配置
6. **删除目录**：移除状态目录和工作空间
7. **卸载 CLI**：通过包管理器移除 CLI 工具
8. **清理应用**：删除桌面应用（macOS）
9. **扫描残留**：检查并清理系统中的残留文件
10. **完成提示**：显示卸载摘要和清理统计

## 安全特性

- **用户确认**：所有关键操作都需要用户明确确认
- **安全通配符**：修复了通配符注入安全问题（commit d0bc769）
- **容错执行**：即使某些步骤失败也能继续执行
- **详细日志**：清晰显示每个步骤的执行结果
- **残留清理**：提供二次扫描和清理机会

## 常见问题

### 卸载失败怎么办？

脚本采用了容错设计，即使某些组件卸载失败也会继续执行。如果遇到问题，可以：

1. 检查是否有权限不足的情况（可能需要 sudo）
2. 手动停止正在运行的 OpenClaw 服务
3. 重新运行卸载脚本

### 会删除我的项目文件吗？

不会。脚本只会删除 OpenClaw 相关的系统文件和配置，不会影响你的项目文件。

### 如何只卸载部分组件？

目前脚本不支持选择性卸载。如果需要保留某些组件，建议手动操作。

## 技术细节

- **Shell 脚本**：Bash，兼容 POSIX 标准
- **Windows 脚本**：PowerShell 5.1+
- **安全措施**：安全的文件操作和通配符处理
- **跨平台兼容**：针对不同操作系统的特定优化

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 作者

akira82-ai

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

- **v1.0** (2025-03-11)
  - 初始版本发布
  - 支持 macOS、Linux、Windows 平台
  - 修复通配符注入安全问题
  - 添加 Windows PowerShell 脚本支持

---

🦞 龙虾已经体面告别。
