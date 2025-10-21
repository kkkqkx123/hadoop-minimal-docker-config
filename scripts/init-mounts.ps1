# Hadoop Docker 挂载目录初始化脚本 (PowerShell版本)
# 用于在WSL环境中创建和检查必要的挂载目录

param(
    [Parameter(Position=0)]
    [string]$Mode = "check",
    
    [Parameter()]
    [switch]$Help
)

# WSL目标路径
$WSL_TARGET = "/home/docker-compose/hadoop"

# 挂载目录列表
$MountDirs = @(
    "/tmp/hadoop-volumes/namenode",
    "/tmp/hadoop-volumes/datanode1", 
    "/tmp/hadoop-volumes/datanode2",
    "/tmp/hadoop-volumes/yarnlogs"
)

# 颜色定义
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m"
$Reset = "`e[0m"

# 函数：运行WSL命令
function Invoke-WslCommand {
    param([string]$Command)
    wsl -e bash -cl $Command
}

# 函数：检查目录是否存在
function Test-WslDirectory {
    param([string]$DirPath)
    $result = Invoke-WslCommand "test -d '$DirPath' && echo 'EXISTS' || echo 'MISSING'"
    return $result.Trim() -eq "EXISTS"
}

# 函数：创建目录
function New-WslDirectory {
    param([string]$DirPath)
    Write-Host "${Yellow}→${Reset} 创建目录: $DirPath"
    $result = Invoke-WslCommand "mkdir -p '$DirPath' && echo 'SUCCESS' || echo 'FAILED'"
    if ($result.Trim() -eq "SUCCESS") {
        Write-Host "${Green}✓${Reset} 目录创建成功: $DirPath"
        return $true
    } else {
        Write-Host "${Red}✗${Reset} 目录创建失败: $DirPath"
        return $false
    }
}

# 函数：设置目录权限
function Set-WslDirectoryPermissions {
    param([string]$DirPath)
    Write-Host "${Yellow}→${Reset} 设置权限: $DirPath"
    $result = Invoke-WslCommand "chmod 755 '$DirPath' && echo 'SUCCESS' || echo 'FAILED'"
    if ($result.Trim() -eq "SUCCESS") {
        Write-Host "${Green}✓${Reset} 权限设置成功: $DirPath"
        return $true
    } else {
        Write-Host "${Red}✗${Reset} 权限设置失败: $DirPath"
        return $false
    }
}

# 函数：显示帮助信息
function Show-Help {
    Write-Host @"
==========================================
Hadoop Docker 挂载目录初始化工具 (PowerShell)
==========================================

用法: .\init-mounts.ps1 [模式] [选项]

模式:
  check, -c     检查挂载目录是否存在 (默认)
  init, -i      初始化挂载目录结构
  status, -s    显示详细目录状态
  clean         清理所有挂载目录 (⚠️ 危险操作)

选项:
  -Help          显示此帮助信息

示例:
  .\init-mounts.ps1                    # 检查目录状态
  .\init-mounts.ps1 check              # 检查目录状态
  .\init-mounts.ps1 init                # 初始化目录结构
  .\init-mounts.ps1 status              # 显示详细状态
  .\init-mounts.ps1 clean                # 清理所有目录
  .\init-mounts.ps1 -Help               # 显示帮助

Hadoop Docker 集群所需的挂载目录:
  - /tmp/hadoop-volumes/namenode
  - /tmp/hadoop-volumes/datanode1
  - /tmp/hadoop-volumes/datanode2
  - /tmp/hadoop-volumes/yarnlogs

注意: 此脚本需要在PowerShell中运行，并需要WSL环境支持
"@
}

# 函数：检查模式
function Invoke-CheckMode {
    Write-Host "模式：检查目录状态"
    Write-Host "------------------------"
    
    $allExist = $true
    $missingDirs = @()
    
    foreach ($dir in $MountDirs) {
        if (Test-WslDirectory $dir) {
            Write-Host "${Green}✓${Reset} 目录存在: $dir"
        } else {
            Write-Host "${Red}✗${Reset} 目录不存在: $dir"
            $allExist = $false
            $missingDirs += $dir
        }
    }
    
    Write-Host
    if ($allExist) {
        Write-Host "${Green}✓${Reset} 所有挂载目录都已存在！"
        return 0
    } else {
        Write-Host "${Red}✗${Reset} 部分挂载目录缺失，建议运行初始化命令："
        Write-Host "${Yellow}  .\init-mounts.ps1 init${Reset}"
        return 1
    }
}

# 函数：初始化模式
function Invoke-InitMode {
    Write-Host "模式：初始化目录结构"
    Write-Host "------------------------"
    
    $successCount = 0
    $totalCount = $MountDirs.Count
    
    foreach ($dir in $MountDirs) {
        Write-Host
        if (-not (Test-WslDirectory $dir)) {
            if (New-WslDirectory $dir) {
                if (Set-WslDirectoryPermissions $dir) {
                    $successCount++
                }
            }
        } else {
            Write-Host "${Green}✓${Reset} 目录已存在，跳过创建: $dir"
            $successCount++
        }
    }
    
    Write-Host
    Write-Host "=========================================="
    if ($successCount -eq $totalCount) {
        Write-Host "${Green}✓${Reset} 目录初始化完成！ ($successCount/$totalCount)"
        Write-Host
        Write-Host "现在可以安全地启动 Hadoop Docker 集群："
        Write-Host "${Yellow}  wsl -e bash -cl \"cd $WSL_TARGET && docker-compose up -d\"${Reset}"
    } else {
        Write-Host "${Red}✗${Reset} 目录初始化失败！ ($successCount/$totalCount)"
        exit 1
    }
}

# 函数：状态模式
function Invoke-StatusMode {
    Write-Host "模式：详细状态检查"
    Write-Host "------------------------"
    
    foreach ($dir in $MountDirs) {
        if (Test-WslDirectory $dir) {
            Write-Host "${Green}✓${Reset} $dir (存在)"
            $details = Invoke-WslCommand "ls -ld '$dir' 2>/dev/null"
            if ($details) {
                Write-Host "    $details"
            }
        } else {
            Write-Host "${Red}✗${Reset} $dir (不存在)"
        }
        Write-Host
    }
}

# 函数：清理模式
function Invoke-CleanMode {
    Write-Host "${Red}⚠${Reset}  警告：此操作将删除所有挂载目录及其内容！"
    $response = Read-Host "是否继续？ [y/N]"
    
    if ($response -match "^[Yy]$") {
        Write-Host
        Write-Host "清理挂载目录..."
        foreach ($dir in $MountDirs) {
            if (Test-WslDirectory $dir) {
                Write-Host "${Yellow}→${Reset} 删除目录: $dir"
                Invoke-WslCommand "rm -rf '$dir'"
            }
        }
        Write-Host "${Green}✓${Reset} 清理完成！"
    } else {
        Write-Host "操作已取消。"
    }
}

# 主程序
function Main {
    Write-Host "=========================================="
    Write-Host "Hadoop Docker 挂载目录初始化工具 (PowerShell)"
    Write-Host "=========================================="
    Write-Host
    
    # 检查WSL是否可用
    try {
        $wslCheck = wsl -e bash -c "echo 'WSL_OK'" 2>$null
        if ($wslCheck -notcontains "WSL_OK") {
            throw "WSL不可用"
        }
    } catch {
        Write-Host "${Red}错误：${Reset} WSL环境不可用，请确保WSL已正确安装和配置"
        exit 1
    }
    
    # 处理帮助选项
    if ($Help) {
        Show-Help
        return
    }
    
    # 根据模式执行相应操作
    switch ($Mode.ToLower()) {
        "check" { Invoke-CheckMode }
        "init"  { Invoke-InitMode }
        "status"{ Invoke-StatusMode }
        "clean" { Invoke-CleanMode }
        "help"  { Show-Help }
        default {
            Write-Host "${Red}错误：${Reset}未知模式: $Mode"
            Write-Host "运行 '.\init-mounts.ps1 -Help' 获取帮助信息"
            exit 1
        }
    }
}

# 运行主程序
Main