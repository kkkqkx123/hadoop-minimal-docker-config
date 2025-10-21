#!/bin/bash

# Hadoop Docker 挂载目录初始化脚本
# 用于在WSL环境中创建和检查必要的挂载目录

set -e

# 定义挂载目录路径
MOUNT_DIRS=(
    "/tmp/hadoop-volumes/namenode"
    "/tmp/hadoop-volumes/datanode1"
    "/tmp/hadoop-volumes/datanode2"
    "/tmp/hadoop-volumes/yarnlogs"
)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函数：检查目录是否存在
check_directory() {
    local dir_path=$1
    if [ -d "$dir_path" ]; then
        echo -e "${GREEN}✓${NC} 目录存在: $dir_path"
        return 0
    else
        echo -e "${RED}✗${NC} 目录不存在: $dir_path"
        return 1
    fi
}

# 函数：创建目录
create_directory() {
    local dir_path=$1
    echo -e "${YELLOW}→${NC} 创建目录: $dir_path"
    mkdir -p "$dir_path"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} 目录创建成功: $dir_path"
        return 0
    else
        echo -e "${RED}✗${NC} 目录创建失败: $dir_path"
        return 1
    fi
}

# 函数：设置目录权限
set_permissions() {
    local dir_path=$1
    echo -e "${YELLOW}→${NC} 设置权限: $dir_path"
    chmod 755 "$dir_path"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} 权限设置成功: $dir_path"
        return 0
    else
        echo -e "${RED}✗${NC} 权限设置失败: $dir_path"
        return 1
    fi
}

# 函数：显示目录状态
show_directory_status() {
    local dir_path=$1
    if [ -d "$dir_path" ]; then
        echo -e "${GREEN}✓${NC} $dir_path (存在)"
        ls -ld "$dir_path" 2>/dev/null || true
    else
        echo -e "${RED}✗${NC} $dir_path (不存在)"
    fi
}

# 主函数
main() {
    echo "=========================================="
    echo "Hadoop Docker 挂载目录初始化工具"
    echo "=========================================="
    echo
    
    # 检查是否以root权限运行
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}⚠${NC}  注意：建议以root权限运行此脚本以确保目录权限正确"
        echo
    fi
    
    # 模式选择
    case "${1:-check}" in
        "check"|"-c"|"--check")
            echo "模式：检查目录状态"
            echo "------------------------"
            all_exist=true
            for dir in "${MOUNT_DIRS[@]}"; do
                if ! check_directory "$dir"; then
                    all_exist=false
                fi
            done
            echo
            if $all_exist; then
                echo -e "${GREEN}✓${NC} 所有挂载目录都已存在！"
                exit 0
            else
                echo -e "${RED}✗${NC} 部分挂载目录缺失，建议运行初始化命令："
                echo -e "${YELLOW}  ./init-mounts.sh init${NC}"
                exit 1
            fi
            ;;
            
        "init"|"-i"|"--init")
            echo "模式：初始化目录结构"
            echo "------------------------"
            success_count=0
            total_count=${#MOUNT_DIRS[@]}
            
            for dir in "${MOUNT_DIRS[@]}"; do
                echo
                if [ ! -d "$dir" ]; then
                    if create_directory "$dir"; then
                        if set_permissions "$dir"; then
                            ((success_count++))
                        fi
                    fi
                else
                    echo -e "${GREEN}✓${NC} 目录已存在，跳过创建: $dir"
                    ((success_count++))
                fi
            done
            
            echo
            echo "=========================================="
            if [ $success_count -eq $total_count ]; then
                echo -e "${GREEN}✓${NC} 目录初始化完成！ ($success_count/$total_count)"
                echo
                echo "现在可以安全地启动 Hadoop Docker 集群："
                echo -e "${YELLOW}  docker-compose up -d${NC}"
            else
                echo -e "${RED}✗${NC} 目录初始化失败！ ($success_count/$total_count)"
                exit 1
            fi
            ;;
            
        "status"|"-s"|"--status")
            echo "模式：详细状态检查"
            echo "------------------------"
            for dir in "${MOUNT_DIRS[@]}"; do
                show_directory_status "$dir"
                echo
            done
            ;;
            
        "clean"|"--clean")
            echo -e "${RED}⚠${NC}  警告：此操作将删除所有挂载目录及其内容！"
            echo -n "是否继续？ [y/N]: "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                echo
                echo "清理挂载目录..."
                for dir in "${MOUNT_DIRS[@]}"; do
                    if [ -d "$dir" ]; then
                        echo -e "${YELLOW}→${NC} 删除目录: $dir"
                        rm -rf "$dir"
                    fi
                done
                echo -e "${GREEN}✓${NC} 清理完成！"
            else
                echo "操作已取消。"
            fi
            ;;
            
        "help"|"-h"|"--help"|"")
            echo "用法: $0 [选项]"
            echo
            echo "选项:"
            echo "  check, -c, --check     检查挂载目录是否存在 (默认)"
            echo "  init, -i, --init       初始化挂载目录结构"
            echo "  status, -s, --status    显示详细目录状态"
            echo "  clean, --clean         清理所有挂载目录 (⚠️ 危险操作)"
            echo "  help, -h, --help       显示此帮助信息"
            echo
            echo "示例:"
            echo "  $0                      # 检查目录状态"
            echo "  $0 check                # 检查目录状态"
            echo "  $0 init                 # 初始化目录结构"
            echo "  $0 status               # 显示详细状态"
            echo "  $0 clean                # 清理所有目录"
            echo
            echo "Hadoop Docker 集群所需的挂载目录:"
            for dir in "${MOUNT_DIRS[@]}"; do
                echo "  - $dir"
            done
            ;;
            
        *)
            echo -e "${RED}错误：${NC}未知选项: $1"
            echo "运行 '$0 help' 获取帮助信息"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"