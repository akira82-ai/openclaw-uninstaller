#Requires -Version 5.1

# 错误处理设置
$ErrorActionPreference = "Continue"

# 颜色辅助函数
function Print-Step {
    param([string]$Message)
    Write-Host "[步骤] $Message" -ForegroundColor Cyan
}

function Print-Success {
    param([string]$Message)
    Write-Host "[成功] $Message" -ForegroundColor Green
}

function Print-Warning {
    param([string]$Message)
    Write-Host "[警告] $Message" -ForegroundColor Yellow
}

function Print-Error {
    param([string]$Message)
    Write-Host "[错误] $Message" -ForegroundColor Red
}

# 显示横幅
function Show-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor White
    Write-Host "║                                                                ║" -ForegroundColor White
    Write-Host "║          OpenClaw 一键卸载器 v1.0 (Windows)                    ║" -ForegroundColor White
    Write-Host "║          体面告别 OpenClaw                                      ║" -ForegroundColor White
    Write-Host "║                                                                ║" -ForegroundColor White
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor White
    Write-Host ""
}

# 检查 CLI 是否可用
function Test-CLIAvailable {
    $null = Get-Command openclaw -ErrorAction SilentlyContinue
    return $?
}

# 查找所有状态目录
function Find-AllStateDirs {
    $homeDir = $env:USERPROFILE
    $openclawDirs = @()

    # 默认目录
    $defaultDir = Join-Path $homeDir ".openclaw"
    if (Test-Path $defaultDir) {
        $openclawDirs += $defaultDir
    }

    # Profile 目录
    $profileDirs = Get-ChildItem -Path $homeDir -Filter ".openclaw-*" -Directory -ErrorAction SilentlyContinue
    if ($profileDirs) {
        $openclawDirs += $profileDirs.FullName
    }

    # 环境变量指定的目录
    if ($env:OPENCLAW_STATE_DIR -and (Test-Path $env:OPENCLAW_STATE_DIR)) {
        $openclawDirs += $env:OPENCLAW_STATE_DIR
    }

    return $openclawDirs
}

# 计算目录大小
function Get-DirSize {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return "0 B"
    }

    try {
        $size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum

        if ($size -and $size -gt 0) {
            return Format-FileSize $size
        }
        return "未知"
    }
    catch {
        return "未知"
    }
}

# 格式化文件大小
function Format-FileSize {
    param([long]$Size)

    if ($Size -ge 1GB) {
        return "{0:N2} GB" -f ($Size / 1GB)
    }
    elseif ($Size -ge 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    }
    elseif ($Size -ge 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    }
    else {
        return "$Size B"
    }
}

# 检测服务状态
function Test-ServiceRunning {
    $serviceName = "openclaw-gateway"

    try {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            return $true
        }
    }
    catch {
        # 忽略错误
    }

    return $false
}

# 检测 CLI 安装方式
function Get-CLIInstallMethod {
    # 检查 npm
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        $npmList = npm list -g openclaw 2>$null | Out-String
        if ($npmList -match 'openclaw@') {
            return "npm"
        }
    }

    # 检查 pnpm
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        $pnpmList = pnpm list -g openclaw 2>$null | Out-String
        if ($pnpmList -match 'openclaw@') {
            return "pnpm"
        }
    }

    # 检查 bun
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        $bunList = bun pm ls -g openclaw 2>$null | Out-String
        if ($bunList -match 'openclaw@') {
            return "bun"
        }
    }

    return "unknown"
}

# 显示检测结果
function Show-DetectionSummary {
    param(
        [bool]$CLIAvailable,
        [bool]$ServiceRunning,
        [string]$CLIMethod
    )

    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
    Write-Host "检测到以下 OpenClaw 组件：" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
    Write-Host ""

    # 状态目录
    Write-Host "[状态目录]" -ForegroundColor Cyan
    $stateDirs = Find-AllStateDirs

    if ($stateDirs.Count -eq 0) {
        Write-Host "   未找到状态目录" -ForegroundColor Yellow
    }
    else {
        foreach ($dir in $stateDirs) {
            $size = Get-DirSize $dir
            Write-Host "   [√]" -NoNewline -ForegroundColor Green
            Write-Host " $dir ($size)"
        }
    }
    Write-Host ""

    # 工作空间
    Write-Host "[工作空间]" -ForegroundColor Cyan
    $workspacePath = Join-Path $env:USERPROFILE ".openclaw\workspace"
    if (Test-Path $workspacePath) {
        $size = Get-DirSize $workspacePath
        Write-Host "   [√]" -NoNewline -ForegroundColor Green
        Write-Host " $workspacePath ($size)"
    }
    else {
        Write-Host "   未找到工作空间" -ForegroundColor Yellow
    }
    Write-Host ""

    # 系统服务
    Write-Host "[系统服务]" -ForegroundColor Cyan
    if ($ServiceRunning) {
        Write-Host "   [√]" -NoNewline -ForegroundColor Green
        Write-Host " openclaw-gateway (运行中)"
    }
    else {
        Write-Host "   未检测到运行中的服务" -ForegroundColor Yellow
    }
    Write-Host ""

    # CLI 安装
    Write-Host "[CLI 安装]" -ForegroundColor Cyan
    if ($CLIAvailable) {
        if ($CLIMethod -ne "unknown") {
            Write-Host "   [√]" -NoNewline -ForegroundColor Green
            Write-Host " $CLIMethod 全局安装"
        }
        else {
            Write-Host "   [√]" -NoNewline -ForegroundColor Green
            Write-Host " CLI 可用（安装方式未知）"
        }
    }
    else {
        Write-Host "   未检测到 CLI" -ForegroundColor Yellow
    }
    Write-Host ""

    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
}

# 请求用户确认
function Request-Confirmation {
    $response = Read-Host "确认卸载？[y/N]"
    return $response -match '^[Yy]$'
}

# 停止网关服务
function Stop-GatewayService {
    param([bool]$CLIAvailable)

    if ($CLIAvailable) {
        $result = & openclaw gateway stop 2>$null
        if ($LASTEXITCODE -eq 0) {
            Print-Success "网关服务已停止"
            return 0
        }
        else {
            Print-Warning "网关服务可能已经停止或不存在"
            return 1
        }
    }
    else {
        # 手动停止服务
        try {
            $service = Get-Service -Name "openclaw-gateway" -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq 'Running') {
                Stop-Service -Name "openclaw-gateway" -Force -ErrorAction SilentlyContinue
                Print-Success "已停止网关服务"
                return 0
            }
        }
        catch {
            # 忽略错误
        }

        Print-Warning "网关服务可能已经停止"
        return 1
    }
}

# 卸载网关服务
function Uninstall-GatewayService {
    param([bool]$CLIAvailable)

    if ($CLIAvailable) {
        $result = & openclaw gateway uninstall 2>$null
        if ($LASTEXITCODE -eq 0) {
            Print-Success "网关服务已卸载"
            return 0
        }
        else {
            Print-Warning "网关服务可能已经卸载"
            return 1
        }
    }
    else {
        # Windows 不需要手动删除服务配置文件
        Print-Warning "服务配置可能已经删除"
        return 1
    }
}

# 删除状态目录
function Remove-StateDirectories {
    $removedCount = 0
    $stateDirs = Find-AllStateDirs

    foreach ($dir in $stateDirs) {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
            Print-Success "已删除: $dir"
            $removedCount++
        }
    }

    return $removedCount
}

# 删除工作空间
function Remove-Workspace {
    $workspacePath = Join-Path $env:USERPROFILE ".openclaw\workspace"

    if (Test-Path $workspacePath) {
        Remove-Item -Path $workspacePath -Recurse -Force -ErrorAction SilentlyContinue
        Print-Success "已删除工作空间"
        return 0
    }
    else {
        Print-Warning "工作空间不存在"
        return 1
    }
}

# 卸载 CLI
function Uninstall-CLI {
    param([string]$CLIMethod)

    switch ($CLIMethod) {
        "npm" {
            $result = npm uninstall -g openclaw 2>$null
            if ($LASTEXITCODE -eq 0) {
                Print-Success "已通过 npm 卸载 CLI"
                return 0
            }
        }
        "pnpm" {
            $result = pnpm remove -g openclaw 2>$null
            if ($LASTEXITCODE -eq 0) {
                Print-Success "已通过 pnpm 卸载 CLI"
                return 0
            }
        }
        "bun" {
            $result = bun remove -g openclaw 2>$null
            if ($LASTEXITCODE -eq 0) {
                Print-Success "已通过 bun 卸载 CLI"
                return 0
            }
        }
        default {
            Print-Warning "未能自动卸载 CLI，可能需要手动处理"
            return 1
        }
    }
}

# 显示清理摘要
function Show-CleanupSummary {
    param(
        [int]$StateDirsCount,
        [int]$WorkspaceSuccess,
        [int]$CLISuccess,
        [int]$ServiceSuccess
    )

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
    Write-Host "[OK] OpenClaw 已成功卸载！" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
    Write-Host ""
    Write-Host "已清理："

    if ($StateDirsCount -gt 0) {
        Write-Host "• $StateDirsCount 个状态目录"
    }
    if ($WorkspaceSuccess -eq 0) {
        Write-Host "• 工作空间"
    }
    if ($ServiceSuccess -eq 0) {
        Write-Host "• 系统服务"
    }
    if ($CLISuccess -eq 0) {
        Write-Host "• CLI 本体"
    }

    Write-Host ""
    Write-Host "OpenClaw 已经体面告别。" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor White
    Write-Host ""
}

# 扫描并清理残留文件
function Scan-AndCleanupRemainingFiles {
    Print-Step "扫描系统中残留的 openclaw 文件..."

    $remainingFiles = @()
    $hasGlobalConfig = $false

    # 扫描常见位置（统一在一个地方定义）
    $locations = @(
        @{Path = (Join-Path $env:USERPROFILE ".openclawrc"); IsGlobalConfig = $true},
        @{Path = (Join-Path $env:USERPROFILE ".openclaw.config"); IsGlobalConfig = $true},
        @{Path = (Join-Path $env:APPDATA "openclaw"); IsGlobalConfig = $false},
        @{Path = (Join-Path $env:LOCALAPPDATA "openclaw"); IsGlobalConfig = $false}
    )

    # 临时文件
    $tempPath = $env:TEMP
    if ($tempPath) {
        $tempOpenclaw = Get-ChildItem -Path $tempPath -Filter "openclaw*" -ErrorAction SilentlyContinue
        if ($tempOpenclaw) {
            foreach ($item in $tempOpenclaw) {
                $locations += @{Path = $item.FullName; IsGlobalConfig = $false}
            }
        }
    }

    foreach ($loc in $locations) {
        $path = $loc.Path
        if (Test-Path $path) {
            $remainingFiles += $path
            if ($loc.IsGlobalConfig) {
                $hasGlobalConfig = $true
            }
        }
    }

    if ($remainingFiles.Count -eq 0) {
        Print-Success "未发现残留文件"
        return
    }

    # 显示找到的文件
    Write-Host ""
    Write-Host "发现 $($remainingFiles.Count) 个残留文件/目录：" -ForegroundColor Yellow
    Write-Host ""

    # 如果有全局配置文件，显示警告
    if ($hasGlobalConfig) {
        Write-Host "[!] 警告：检测到全局配置文件，删除可能影响其他系统或项目" -ForegroundColor Yellow
        Write-Host ""
    }

    foreach ($file in $remainingFiles) {
        if (Test-Path $file -PathType Container) {
            $size = Get-DirSize $file
            Write-Host "   [DIR]" -NoNewline -ForegroundColor Cyan
            Write-Host " $file ($size)"
        }
        else {
            $size = (Get-Item $file -ErrorAction SilentlyContinue).Length
            if ($size) {
                $formattedSize = Format-FileSize $size
                Write-Host "   [FILE]" -NoNewline -ForegroundColor Cyan
                Write-Host " $file ($formattedSize)"
            }
            else {
                Write-Host "   [FILE]" -NoNewline -ForegroundColor Cyan
                Write-Host " $file"
            }
        }
    }
    Write-Host ""

    # 询问是否删除
    $response = Read-Host "是否删除这些残留文件？[y/N]"
    Write-Host ""

    if ($response -notmatch '^[Yy]$') {
        Print-Warning "跳过残留文件清理"
        return
    }

    # 执行删除
    $deletedCount = 0
    foreach ($file in $remainingFiles) {
        Remove-Item -Path $file -Recurse -Force -ErrorAction SilentlyContinue
        if ($?) {
            $deletedCount++
        }
        else {
            Print-Warning "无法删除 $file"
        }
    }

    Print-Success "已删除 $deletedCount 个残留文件"

    # 询问是否删除卸载脚本本身
    Write-Host ""
    $response = Read-Host "是否删除卸载器脚本本身？[y/N]"
    Write-Host ""

    if ($response -match '^[Yy]$') {
        $scriptPath = $PSCommandPath
        if ($scriptPath -and (Test-Path $scriptPath)) {
            try {
                Remove-Item -Path $scriptPath -Force
                Print-Success "脚本已自删除"
            }
            catch {
                Print-Warning "无法删除脚本：$_"
            }
        }
        else {
            Print-Warning "脚本路径无效或不存在"
        }
    }
}

# 主函数
function Main {
    Show-Banner

    # 环境检测
    Print-Step "检测到操作系统: Windows"

    $cliAvailable = Test-CLIAvailable
    $serviceRunning = Test-ServiceRunning
    $cliMethod = Get-CLIInstallMethod

    Write-Host ""

    # 显示检测摘要
    Show-DetectionSummary -CLIAvailable $cliAvailable -ServiceRunning $serviceRunning -CLIMethod $cliMethod

    # 请求确认
    if (-not (Request-Confirmation)) {
        Print-Warning "已取消卸载"
        exit 0
    }

    Write-Host ""

    # 执行清理
    $totalSteps = 5
    $currentStep = 1

    Write-Host "开始执行清理..." -ForegroundColor White
    Write-Host ""

    # 步骤 1: 停止服务
    Print-Step "[$currentStep/$totalSteps] 停止网关服务..."
    $serviceRemoved = Stop-GatewayService -CLIAvailable $cliAvailable
    $currentStep++
    Write-Host ""

    # 步骤 2: 卸载服务
    Print-Step "[$currentStep/$totalSteps] 卸载网关服务..."
    $serviceRemoved = Uninstall-GatewayService -CLIAvailable $cliAvailable
    $currentStep++
    Write-Host ""

    # 步骤 3: 删除状态目录
    Print-Step "[$currentStep/$totalSteps] 删除状态目录..."
    $stateDirsCount = Remove-StateDirectories
    $currentStep++
    Write-Host ""

    # 步骤 4: 删除工作空间
    Print-Step "[$currentStep/$totalSteps] 删除工作空间..."
    $workspaceRemoved = Remove-Workspace
    $currentStep++
    Write-Host ""

    # 步骤 5: 卸载 CLI
    Print-Step "[$currentStep/$totalSteps] 卸载 CLI..."
    $cliRemoved = Uninstall-CLI -CLIMethod $cliMethod
    Write-Host ""

    # 显示完成信息
    Show-CleanupSummary -StateDirsCount $stateDirsCount -WorkspaceSuccess $workspaceRemoved -CLISuccess $cliRemoved -ServiceSuccess $serviceRemoved

    # 扫描并清理残留文件
    Scan-AndCleanupRemainingFiles
}

# 运行主函数
Main
