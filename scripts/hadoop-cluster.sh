#!/bin/bash

# Hadoop Docker 集群管理脚本
# 集成挂载目录检查和集群启动功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：显示帮助信息
show_help() {
    cat << EOF
==========================================
Hadoop Docker 集群管理工具
==========================================

用法: $0 [命令] [选项]

命令:
  init        初始化挂载目录并启动集群
  start       启动集群（检查挂载目录）
  stop        停止集群
  restart     重启集群
  status      查看集群状态
  logs        查看集群日志
  clean       清理所有数据（⚠️ 危险操作）
  help        显示此帮助信息

选项:
  -f, --force    强制操作（用于清理）
  -v, --verbose  详细输出

示例:
  $0 init          # 首次初始化并启动
  $0 start         # 启动集群
  $0 stop          # 停止集群
  $0 status        # 查看状态
  $0 logs master   # 查看master节点日志
  $0 clean --force # 强制清理所有数据

Web UI 地址:
  NameNode:        http://localhost:9870
  ResourceManager: http://localhost:8088
  NodeManager1:    http://localhost:8042
  NodeManager2:    http://localhost:8043

EOF
}

# 函数：检查挂载目录
check_mounts() {
    echo -e "${BLUE}检查挂载目录...${NC}"
    
    local missing_dirs=()
    local mount_dirs=(
        "/tmp/hadoop-volumes/namenode"
        "/tmp/hadoop-volumes/datanode1"
        "/tmp/hadoop-volumes/datanode2"
        "/tmp/hadoop-volumes/yarnlogs"
    )
    
    for dir in "${mount_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
            echo -e "${RED}❌ 缺失: $dir${NC}"
        else
            echo -e "${GREEN}✅ 存在: $dir${NC}"
        fi
    done
    
    if [ ${#missing_dirs[@]} -gt 0 ]; then
        echo -e "${YELLOW}创建缺失的挂载目录...${NC}"
        for dir in "${missing_dirs[@]}"; do
            mkdir -p "$dir"
            chmod 755 "$dir"
            echo -e "${GREEN}✅ 创建: $dir${NC}"
        done
    fi
    
    echo -e "${GREEN}✅ 挂载目录检查完成${NC}"
}

# 函数：启动集群
start_cluster() {
    echo -e "${BLUE}启动 Hadoop Docker 集群...${NC}"
    
    # 检查挂载目录
    check_mounts
    
    # 启动集群
    echo -e "${YELLOW}正在启动容器...${NC}"
    if docker-compose up -d; then
        echo -e "${GREEN}✅ 集群启动成功！${NC}"
        
        # 等待服务启动
        echo -e "${YELLOW}等待服务启动...${NC}"
        sleep 5
        
        # 显示状态
        show_status
        
        echo
        echo -e "${GREEN}🎉 Hadoop 集群已成功启动！${NC}"
        echo -e "${BLUE}Web UI 访问地址：${NC}"
        echo "  NameNode:        http://localhost:9870"
        echo "  ResourceManager: http://localhost:8088"
        echo "  NodeManager1:    http://localhost:8042"
        echo "  NodeManager2:    http://localhost:8043"
    else
        echo -e "${RED}❌ 集群启动失败！${NC}"
        echo "请检查日志：docker-compose logs"
        exit 1
    fi
}

# 函数：停止集群
stop_cluster() {
    echo -e "${BLUE}停止 Hadoop Docker 集群...${NC}"
    
    if docker-compose down; then
        echo -e "${GREEN}✅ 集群已停止${NC}"
    else
        echo -e "${RED}❌ 停止失败！${NC}"
        exit 1
    fi
}

# 函数：查看状态
show_status() {
    echo -e "${BLUE}集群状态：${NC}"
    docker-compose ps
    
    echo
    echo -e "${BLUE}容器状态详情：${NC}"
    for service in master worker1 worker2; do
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "^$service"; then
            status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "^$service" | awk '{print $2}')
            echo -e "${GREEN}✅ $service: $status${NC}"
        else
            echo -e "${RED}❌ $service: 未运行${NC}"
        fi
    done
}

# 函数：查看日志
show_logs() {
    local service=$1
    
    if [ -n "$service" ]; then
        echo -e "${BLUE}查看 $service 日志：${NC}"
        docker-compose logs -f "$service"
    else
        echo -e "${BLUE}查看所有服务日志：${NC}"
        docker-compose logs -f
    fi
}

# 函数：清理数据
clean_data() {
    local force=$1
    
    if [ "$force" != "true" ]; then
        echo -e "${RED}⚠️  警告：此操作将删除所有Hadoop数据！${NC}"
        echo -n "是否继续？ [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "操作已取消。"
            return
        fi
    fi
    
    echo -e "${YELLOW}正在清理数据...${NC}"
    
    # 停止集群
    docker-compose down 2>/dev/null || true
    
    # 删除数据目录
    for dir in /tmp/hadoop-volumes/namenode /tmp/hadoop-volumes/datanode1 /tmp/hadoop-volumes/datanode2 /tmp/hadoop-volumes/yarnlogs; do
        if [ -d "$dir" ]; then
            echo -e "${YELLOW}删除: $dir${NC}"
            rm -rf "$dir"
        fi
    done
    
    # 删除Docker卷
    docker volume prune -f
    
    echo -e "${GREEN}✅ 数据清理完成！${NC}"
}

# 函数：测试集群
test_cluster() {
    echo -e "${BLUE}测试集群功能...${NC}"
    
    # 等待NameNode启动
    echo -e "${YELLOW}等待NameNode启动...${NC}"
    for i in {1..30}; do
        if curl -s http://localhost:9870 > /dev/null; then
            echo -e "${GREEN}✅ NameNode Web UI 可访问${NC}"
            break
        fi
        if [ $i -eq 30 ]; then
            echo -e "${RED}❌ NameNode 启动超时${NC}"
            return 1
        fi
        sleep 2
    done
    
    # 测试HDFS
    echo -e "${YELLOW}测试HDFS...${NC}"
    if docker exec master hdfs dfsadmin -report 2>/dev/null | grep -q "Live datanodes"; then
        echo -e "${GREEN}✅ HDFS 正常运行${NC}"
    else
        echo -e "${RED}❌ HDFS 测试失败${NC}"
    fi
    
    # 测试YARN
    echo -e "${YELLOW}测试YARN...${NC}"
    if docker exec master yarn node -list 2>/dev/null | grep -q "Total Nodes:"; then
        echo -e "${GREEN}✅ YARN 正常运行${NC}"
    else
        echo -e "${RED}❌ YARN 测试失败${NC}"
    fi
}

# 主程序
main() {
    case "${1:-help}" in
        "init")
            start_cluster
            ;;
        "start")
            start_cluster
            ;;
        "stop")
            stop_cluster
            ;;
        "restart")
            stop_cluster
            sleep 2
            start_cluster
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$2"
            ;;
        "test")
            test_cluster
            ;;
        "clean")
            force="false"
            if [ "$2" = "--force" ] || [ "$2" = "-f" ]; then
                force="true"
            fi
            clean_data "$force"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}错误：未知命令: $1${NC}"
            echo "运行 '$0 help' 获取帮助信息"
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"