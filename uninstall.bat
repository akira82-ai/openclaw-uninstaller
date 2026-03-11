@echo off
REM OpenClaw 一键卸载器 (Windows)
REM 双击此文件运行卸载程序

powershell -ExecutionPolicy Bypass -NoExit -File "%~dp0uninstall.ps1"
