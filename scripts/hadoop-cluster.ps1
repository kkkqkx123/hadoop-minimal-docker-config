# Hadoop Docker 集群管理 PowerShell 脚本
# 提供Windows友好的Hadoop集群管理界面

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [string]$Option = "",
    
    [switch]$Force,
    [switch]$ShowHelp
)

# 颜色定义
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
}

# 帮助信息
function Show-Help {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Hadoop Docker 集群管理工具 (PowerShell)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "用法: .\hadoop-cluster.ps1 [命令] [选项]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "命令:" -ForegroundColor Blue
    Write-Host "  init        初始化挂载目录并启动集群"
    Write-Host "  start       启动集群（检查挂载目录）"
    Write-Host "  stop        停止集群"
    Write-Host "  restart     重启集群"
    Write-Host "  status      查看集群状态"
    Write-Host "  logs        查看集群日志"
    Write-Host "  test        测试集群功能"
    Write-Host "  clean       清理所有数据（⚠️ 危险操作）"
    Write-Host "  help        显示此帮助信息"
    Write-Host ""
    Write-Host "选项:" -ForegroundColor Blue
    Write-Host "  -Force       强制操作（用于清理）"
    Write-Host "  -ShowHelp    显示帮助信息"
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Blue
    Write-Host "  .\hadoop-cluster.ps1 init          # 首次初始化并启动"
    Write-Host "  .\hadoop-cluster.ps1 start         # 启动集群"
    Write-Host "  .\hadoop-cluster.ps1 stop          # 停止集群"
    Write-Host "  .\hadoop-cluster.ps1 status        # 查看状态"
    Write-Host "  .\hadoop-cluster.ps1 logs master   # 查看master节点日志"
    Write-Host "  .\hadoop-cluster.ps1 clean -Force  # 强制清理所有数据"
    Write-Host ""
    Write-Host "Web UI 地址:" -ForegroundColor Blue
    Write-Host "  NameNode:        http://localhost:9870"
    Write-Host "  ResourceManager: http://localhost:8088"
    Write-Host "  NodeManager1:    http://localhost:8042"
    Write-Host "  NodeManager2:    http://localhost:8043"
    Write-Host ""
}

# 执行WSL命令
function Invoke-WSLCommand {
    param(
        [string]$Command,
        [string]$Option = ""
    )
    
    $wslTarget = "/home/docker-compose/hadoop"
    $scriptPath = "$wslTarget/scripts/hadoop-cluster.sh"
    
    if ($Force) {
        $Option = "--force"
    }
    
    $fullCommand = "cd $wslTarget && $scriptPath $Command $Option"
    
    Write-Verbose "执行命令: wsl -e bash -cl `"$fullCommand`""
    
    try {
        wsl -e bash -cl $fullCommand
        return $true
    }
    catch {
        Write-Error "命令执行失败: $_"
        return $false
    }
}

# 检查WSL环境
function Test-WSLEnvironment {
    Write-Host "检查WSL环境..." -ForegroundColor Blue
    
    # 检查WSL是否可用
    try {
        $null = wsl --status
    }
    catch {
        Write-Error "WSL未安装或未启用，请先安装WSL。"
        return $false
    }
    
    # 检查目标目录是否存在
    $testPath = wsl -e bash -cl "test -d /home/docker-compose/hadoop && echo 'EXISTS'"
    if ($testPath -ne "EXISTS") {
        Write-Error "WSL目标目录 /home/docker-compose/hadoop 不存在，请先同步项目文件。"
        return $false
    }
    
    Write-Host "✅ WSL环境检查通过" -ForegroundColor Green
    return $true
}

# 主程序
function Main {
    if ($ShowHelp) {
        Show-Help
        return
    }
    
    # 检查环境
    if (-not (Test-WSLEnvironment)) {
        return
    }
    
    # 根据命令执行相应操作
    switch ($Command.ToLower()) {
        "init" {
            Write-Host "初始化并启动Hadoop集群..." -ForegroundColor Cyan
            Invoke-WSLCommand -Command "init"
        }
        "start" {
            Write-Host "启动Hadoop集群..." -ForegroundColor Cyan
            Invoke-WSLCommand -Command "start"
        }
        "stop" {
            Write-Host "停止Hadoop集群..." -ForegroundColor Cyan
            Invoke-WSLCommand -Command "stop"
        }
        "restart" {
            Write-Host "重启Hadoop集群..." -ForegroundColor Cyan
            Invoke-WSLCommand -Command "restart"
        }
        "status" {
            Write-Host "查看集群状态..." -ForegroundColor Cyan
            Invoke-WSLCommand -Command "status"
        }
        "logs" {
            Write-Host "查看集群日志..." -ForegroundColor Cyan
            Invoke-WSLCommand -Command "logs" -Option $Option
        }
        "test" {
            Write-Host "测试集群功能..." -ForegroundColor Cyan
            Invoke-WSLCommand -Command "test"
        }
        "clean" {
            if (-not $Force) {
                Write-Host "⚠️ 警告：此操作将删除所有Hadoop数据！" -ForegroundColor Red
                $response = Read-Host "是否继续？ [y/N]"
                if ($response -ne "y" -and $response -ne "Y") {
                    Write-Host "操作已取消。" -ForegroundColor Yellow
                    return
                }
            }
            Write-Host "清理Hadoop数据..." -ForegroundColor Red
            Invoke-WSLCommand -Command "clean" -Option "--force"
        }
        "help" {
            Show-Help
        }
        default {
            Write-Host "错误：未知命令: $Command" -ForegroundColor Red
            Write-Host "运行 '.\hadoop-cluster.ps1 -ShowHelp' 获取帮助信息" -ForegroundColor Yellow
        }
    }
}

# 运行主程序
Main