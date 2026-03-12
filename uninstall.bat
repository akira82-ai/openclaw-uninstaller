@echo off
REM OpenClaw 一键卸载器 (Windows)
REM 双击此文件运行卸载程序

REM 检查 PowerShell 是否可用
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo 错误：未找到 PowerShell，无法运行卸载脚本
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -NoExit -File "%~dp0uninstall.ps1"
