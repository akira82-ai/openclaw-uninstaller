#!/bin/bash

# OpenClaw Uninstaller - 一键卸载工具
# 让这只龙虾体面告别

# 显式错误处理，不使用 set -e 以实现容错性

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_step() {
    echo -e "${BLUE}[步骤]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 显示横幅
show_banner() {
    echo -e "${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║          OpenClaw 一键卸载器 v1.0                              ║"
    echo "║          让这只龙虾体面告别 🦞                                 ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "unknown"
    fi
}

# 检查 CLI 是否可用
check_cli_available() {
    command -v openclaw &> /dev/null && echo "true" || echo "false"
}

# 查找所有状态目录
find_all_state_dirs() {
    home="$HOME"
    openclaw_dirs=()

    # 默认目录
    if [ -d "$home/.openclaw" ]; then
        openclaw_dirs+=("$home/.openclaw")
    fi

    # Profile 目录
    for dir in "$home"/.openclaw-*; do
        if [ -d "$dir" ]; then
            openclaw_dirs+=("$dir")
        fi
    done

    # 环境变量指定的目录
    if [ -n "$OPENCLAW_STATE_DIR" ] && [ -d "$OPENCLAW_STATE_DIR" ]; then
        openclaw_dirs+=("$OPENCLAW_STATE_DIR")
    fi

    printf '%s\n' "${openclaw_dirs[@]}"
}

# 计算目录大小
calculate_dir_size() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "0 B"
        return
    fi

    if command -v du &> /dev/null; then
        local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "${size:-未知}"
    else
        echo "未知"
    fi
}

# 检测服务状态
check_service_running() {
    local os_type="$1"
    local service_running="false"

    if [ "$os_type" == "macos" ]; then
        if launchctl list 2>/dev/null | grep -q "ai.openclaw"; then
            service_running="true"
        fi
    elif [ "$os_type" == "Linux" ]; then
        if systemctl --user is-active --quiet 2>/dev/null; then
            if systemctl --user list-units 2>/dev/null | grep -q "openclaw-gateway"; then
                service_running="true"
            fi
        fi
    fi

    echo "$service_running"
}

# 检测 macOS 应用
check_macos_app() {
    if [ -d "/Applications/OpenClaw.app" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# 检测 CLI 安装方式
detect_cli_install_method() {
    if command -v npm &> /dev/null && npm list -g openclaw &> /dev/null; then
        echo "npm"
    elif command -v pnpm &> /dev/null && pnpm list -g openclaw &> /dev/null; then
        echo "pnpm"
    elif command -v bun &> /dev/null; then
        echo "bun"
    else
        echo "unknown"
    fi
}

# 显示检测结果
show_detection_summary() {
    local os_type="$1"
    local cli_available="$2"
    local service_running="$3"
    local macos_app="$4"
    local cli_method="$5"

    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}检测到以下 OpenClaw 组件：${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # 状态目录
    echo -e "${BLUE}📦 状态目录：${NC}"
    local state_dirs=()
    while IFS= read -r dir; do
        [ -n "$dir" ] && state_dirs+=("$dir")
    done < <(find_all_state_dirs)

    if [ ${#state_dirs[@]} -eq 0 ]; then
        echo -e "   ${YELLOW}未找到状态目录${NC}"
    else
        for dir in "${state_dirs[@]}"; do
            local size=$(calculate_dir_size "$dir")
            echo -e "   ${GREEN}✓${NC} $dir ($size)"
        done
    fi
    echo ""

    # 工作空间
    echo -e "${BLUE}🗑️  工作空间：${NC}"
    if [ -d "$HOME/.openclaw/workspace" ]; then
        local size=$(calculate_dir_size "$HOME/.openclaw/workspace")
        echo -e "   ${GREEN}✓${NC} $HOME/.openclaw/workspace ($size)"
    else
        echo -e "   ${YELLOW}未找到工作空间${NC}"
    fi
    echo ""

    # 系统服务
    echo -e "${BLUE}🔧 系统服务：${NC}"
    if [ "$service_running" == "true" ]; then
        if [ "$os_type" == "macos" ]; then
            echo -e "   ${GREEN}✓${NC} ai.openclaw.gateway (运行中)"
        else
            echo -e "   ${GREEN}✓${NC} openclaw-gateway.service (运行中)"
        fi
    else
        echo -e "   ${YELLOW}未检测到运行中的服务${NC}"
    fi
    echo ""

    # 应用程序（仅 macOS）
    if [ "$os_type" == "macos" ]; then
        echo -e "${BLUE}📱 应用程序：${NC}"
        if [ "$macos_app" == "true" ]; then
            local size=$(calculate_dir_size "/Applications/OpenClaw.app")
            echo -e "   ${GREEN}✓${NC} /Applications/OpenClaw.app ($size)"
        else
            echo -e "   ${YELLOW}未找到 macOS 桌面版${NC}"
        fi
        echo ""
    fi

    # CLI 安装
    echo -e "${BLUE}💻 CLI 安装：${NC}"
    if [ "$cli_available" == "true" ]; then
        if [ "$cli_method" != "unknown" ]; then
            echo -e "   ${GREEN}✓${NC} $cli_method 全局安装"
        else
            echo -e "   ${GREEN}✓${NC} CLI 可用（安装方式未知）"
        fi
    else
        echo -e "   ${YELLOW}未检测到 CLI${NC}"
    fi
    echo ""

    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
}

# 请求用户确认
request_confirmation() {
    echo -n -e "${YELLOW}确认卸载？[y/N]${NC} "
    read -r response
    echo ""
    [[ "$response" =~ ^[Yy]$ ]]
}

# 停止网关服务
stop_gateway_service() {
    local os_type="$1"
    local cli_available="$2"

    if [ "$cli_available" == "true" ]; then
        if openclaw gateway stop 2>/dev/null; then
            print_success "网关服务已停止"
            return 0
        else
            print_warning "网关服务可能已经停止或不存在"
            return 1
        fi
    else
        # 手动停止服务
        if [ "$os_type" == "macos" ]; then
            if launchctl list 2>/dev/null | grep -q "ai.openclaw.gateway"; then
                launchctl bootout "gui/$UID/ai.openclaw.gateway" 2>/dev/null || true
                print_success "已停止网关服务"
                return 0
            fi
        elif [ "$os_type" == "Linux" ]; then
            if systemctl --user is-active openclaw-gateway.service &>/dev/null; then
                systemctl --user stop openclaw-gateway.service 2>/dev/null || true
                print_success "已停止网关服务"
                return 0
            fi
        fi
        print_warning "网关服务可能已经停止"
        return 1
    fi
}

# 卸载网关服务
uninstall_gateway_service() {
    local os_type="$1"
    local cli_available="$2"

    if [ "$cli_available" == "true" ]; then
        if openclaw gateway uninstall 2>/dev/null; then
            print_success "网关服务已卸载"
            return 0
        else
            print_warning "网关服务可能已经卸载"
            return 1
        fi
    else
        # 手动卸载服务
        if [ "$os_type" == "macos" ]; then
            if [ -f "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" ]; then
                rm -f "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
                print_success "已删除服务配置"
                return 0
            fi
        elif [ "$os_type" == "Linux" ]; then
            if [ -f "$HOME/.config/systemd/user/openclaw-gateway.service" ]; then
                systemctl --user disable openclaw-gateway.service 2>/dev/null || true
                rm -f "$HOME/.config/systemd/user/openclaw-gateway.service"
                systemctl --user daemon-reload 2>/dev/null || true
                print_success "已删除服务配置"
                return 0
            fi
        fi
        print_warning "服务配置可能已经删除"
        return 1
    fi
}

# 删除状态目录
remove_state_directories() {
    local removed_count=0
    local total_size=0

    local state_dirs=()
    while IFS= read -r dir; do
        [ -n "$dir" ] && state_dirs+=("$dir")
    done < <(find_all_state_dirs)

    for dir in "${state_dirs[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            print_success "已删除: $dir" >&2
            ((removed_count++)) || true
        fi
    done

    echo "$removed_count"
}

# 删除工作空间
remove_workspace() {
    if [ -d "$HOME/.openclaw/workspace" ]; then
        rm -rf "$HOME/.openclaw/workspace"
        print_success "已删除工作空间" >&2
        return 0
    else
        print_warning "工作空间不存在"
        return 1
    fi
}

# 卸载 CLI
uninstall_cli() {
    local cli_method="$1"

    case "$cli_method" in
        "npm")
            if npm rm -g openclaw 2>/dev/null; then
                print_success "已通过 npm 卸载 CLI"
                return 0
            fi
            ;;
        "pnpm")
            if pnpm remove -g openclaw 2>/dev/null; then
                print_success "已通过 pnpm 卸载 CLI"
                return 0
            fi
            ;;
        "bun")
            if bun remove -g openclaw 2>/dev/null; then
                print_success "已通过 bun 卸载 CLI"
                return 0
            fi
            ;;
        *)
            print_warning "未能自动卸载 CLI，可能需要手动处理"
            return 1
            ;;
    esac
}

# 删除 macOS 应用
remove_macos_app() {
    if [ -d "/Applications/OpenClaw.app" ]; then
        rm -rf "/Applications/OpenClaw.app"
        print_success "已删除 macOS 桌面版" >&2
        return 0
    else
        print_warning "未找到 macOS 桌面版"
        return 1
    fi
}

# 显示清理摘要
show_cleanup_summary() {
    local state_dirs_count="$1"
    local workspace_removed="$2"
    local cli_removed="$3"
    local app_removed="$4"
    local service_removed="$5"

    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ OpenClaw 已成功卸载！${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "已清理："
    [ "$state_dirs_count" -gt 0 ] && echo "• $state_dirs_count 个状态目录"
    [ "$workspace_removed" == "0" ] && echo "• 工作空间"
    [ "$service_removed" == "0" ] && echo "• 系统服务"
    [ "$cli_removed" == "0" ] && echo "• CLI 本体"
    [ "$app_removed" == "0" ] && echo "• macOS 桌面版"
    echo ""
    echo -e "${BOLD}🦞 龙虾已经体面告别。${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# 全盘扫描并清理残留文件
scan_and_cleanup_remaining_files() {
    local os_type="$1"
    local remaining_files=()

    print_step "扫描系统中残留的 openclaw 文件..."

    # 扫描常见位置（结果存储在全局变量 SCAN_RESULT 中）
    SCAN_RESULT=()
    scan_common_locations "$os_type"
    remaining_files=("${SCAN_RESULT[@]}")

    if [ ${#remaining_files[@]} -eq 0 ]; then
        print_success "未发现残留文件"
        return 0
    fi

    # 显示找到的文件
    echo ""
    echo -e "${YELLOW}发现 ${#remaining_files[@]} 个残留文件/目录：${NC}"
    echo ""

    for file in "${remaining_files[@]}"; do
        if [ -d "$file" ]; then
            local size=$(calculate_dir_size "$file")
            echo -e "   ${BLUE}📁${NC} $file ${GRAY}($size)${NC}"
        else
            local size=$(du -h "$file" 2>/dev/null | cut -f1)
            echo -e "   ${BLUE}📄${NC} $file ${GRAY}($size)${NC}"
        fi
    done
    echo ""

    # 询问是否删除
    echo -n -e "${YELLOW}是否删除这些残留文件？[y/N]${NC} "
    read -r response
    echo ""

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_warning "跳过残留文件清理"
        return 0
    fi

    # 执行删除
    local deleted_count=0
    for file in "${remaining_files[@]}"; do
        if [ -d "$file" ]; then
            rm -rf "$file"
        else
            rm -f "$file"
        fi
        ((deleted_count++)) || true
    done

    print_success "已删除 $deleted_count 个残留文件"

    # 询问是否删除卸载脚本本身
    echo ""
    echo -n -e "${YELLOW}是否删除卸载器脚本本身？[y/N]${NC} "
    read -r response
    echo ""

    if [[ "$response" =~ ^[Yy]$ ]]; then
        script_path="$(
            cd "$(dirname "$0")"
            pwd -P
        )/$(basename "$0")"
        if [ -f "$script_path" ]; then
            rm -f "$script_path"
            print_success "脚本已自删除"
        fi
    fi
}

# 扫描常见位置（结果存储在全局变量 SCAN_RESULT 中）
scan_common_locations() {
    local os_type="$1"

    # 通用位置
    local locations=(
        "$HOME/.config/openclaw"
        "$HOME/.local/share/openclaw"
        "$HOME/.openclawrc"
        "$HOME/.openclaw.config"
    )

    # macOS 特定位置
    if [ "$os_type" == "macos" ]; then
        locations+=(
            "$HOME/Library/Application Support/OpenClaw"
            "$HOME/Library/Caches/OpenClaw"
            "$HOME/Library/Preferences/OpenClaw"
            "$HOME/Library/Logs/OpenClaw"
        )
    fi

    # 临时文件
    if [ -n "$TMPDIR" ]; then
        locations+=("$TMPDIR/openclaw"* "$TMPDIR/.openclaw"*)
    else
        locations+=("/tmp/openclaw"* "/tmp/.openclaw"*)
    fi

    # 保存当前的 shell 选项并设置安全的 glob 选项
    local old_opts=$(set +o)
    set -f  # 禁用通配符展开（ noglob ）

    # 检查每个位置，将结果添加到全局变量
    for loc in "${locations[@]}"; do
        # 使用 eval 安全地展开通配符，然后重新启用通配符
        set +f  # 重新启用通配符展开
        local expanded_files=()
        # 使用数组安全地捕获展开的文件
        eval "expanded_files=($loc)"
        set -f  # 再次禁用通配符展开

        # 检查每个展开的文件
        for expanded in "${expanded_files[@]}"; do
            if [ -e "$expanded" ]; then
                SCAN_RESULT+=("$expanded")
            fi
        done
    done

    # 恢复原来的 shell 选项
    eval "$old_opts"
}

# 主函数
main() {
    show_banner

    # 环境检测
    local os_type=$(detect_os)
    if [ "$os_type" == "unknown" ]; then
        print_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi

    print_step "检测到操作系统: $os_type"

    local cli_available=$(check_cli_available)
    local service_running=$(check_service_running "$os_type")
    local macos_app="false"
    local cli_method=$(detect_cli_install_method)

    if [ "$os_type" == "macos" ]; then
        macos_app=$(check_macos_app)
    fi

    echo ""

    # 显示检测摘要
    show_detection_summary "$os_type" "$cli_available" "$service_running" "$macos_app" "$cli_method"

    # 请求确认
    if ! request_confirmation; then
        print_warning "已取消卸载"
        exit 0
    fi

    echo ""

    # 执行清理
    local total_steps=6
    local current_step=1

    echo -e "${BOLD}开始执行清理...${NC}"
    echo ""

    # 步骤 1: 停止服务
    print_step "[$current_step/$total_steps] 停止网关服务..."
    stop_gateway_service "$os_type" "$cli_available"
    local service_removed=$?
    ((current_step++)) || true
    echo ""

    # 步骤 2: 卸载服务
    print_step "[$current_step/$total_steps] 卸载网关服务..."
    uninstall_gateway_service "$os_type" "$cli_available"
    service_removed=$?
    ((current_step++)) || true
    echo ""

    # 步骤 3: 删除状态目录
    print_step "[$current_step/$total_steps] 删除状态目录..."
    local state_dirs_count=$(remove_state_directories)
    ((current_step++)) || true
    echo ""

    # 步骤 4: 删除工作空间
    print_step "[$current_step/$total_steps] 删除工作空间..."
    remove_workspace
    local workspace_removed=$?
    ((current_step++)) || true
    echo ""

    # 步骤 5: 卸载 CLI
    print_step "[$current_step/$total_steps] 卸载 CLI..."
    uninstall_cli "$cli_method"
    local cli_removed=$?
    ((current_step++)) || true
    echo ""

    # 步骤 6: 删除 macOS 应用（如适用）
    local app_removed=1
    if [ "$os_type" == "macos" ]; then
        print_step "[$current_step/$total_steps] 删除 macOS 桌面版..."
        remove_macos_app
        app_removed=$?
        echo ""
    fi

    # 显示完成信息
    show_cleanup_summary "$state_dirs_count" "$workspace_removed" "$cli_removed" "$app_removed" "$service_removed"

    # 扫描并清理残留文件
    scan_and_cleanup_remaining_files "$os_type"
}

# 运行主函数
main
