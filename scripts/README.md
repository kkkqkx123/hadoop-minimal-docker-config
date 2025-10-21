# Hadoop Docker 集群管理脚本

本目录包含用于管理Hadoop Docker集群的脚本工具，支持在WSL环境中快速初始化、启动、停止和管理Hadoop集群。

## 🚀 快速开始

### 环境要求
- Windows 11 操作系统
- WSL (Windows Subsystem for Linux)
- Docker Desktop

### 一键初始化
```powershell
# 使用PowerShell脚本（推荐）
.\scripts\hadoop-cluster.ps1 init

# 或使用Bash脚本（在WSL中）
wsl -e bash -cl "/home/docker-compose/hadoop/scripts/hadoop-cluster.sh init"
```

## 📋 脚本列表

### 1. hadoop-cluster.sh / hadoop-cluster.ps1
**主要集群管理脚本**

功能：
- `init` - 初始化挂载目录并启动集群
- `start` - 启动集群（自动检查挂载目录）
- `stop` - 停止集群
- `restart` - 重启集群
- `status` - 查看集群状态
- `logs [service]` - 查看集群日志
- `test` - 测试集群功能
- `clean` - 清理所有数据（⚠️危险操作）

使用示例：
```powershell
# PowerShell版本
.\scripts\hadoop-cluster.ps1 start
.\scripts\hadoop-cluster.ps1 status
.\scripts\hadoop-cluster.ps1 logs master

# Bash版本（在WSL中）
./scripts/hadoop-cluster.sh start
./scripts/hadoop-cluster.sh status
```

### 2. init-mounts.sh / init-mounts.ps1
**挂载目录管理脚本**

功能：
- `check` - 检查挂载目录是否存在
- `init` - 初始化挂载目录
- `status` - 显示挂载目录详细信息
- `clean` - 清理挂载目录
- `help` - 显示帮助信息

使用示例：
```powershell
# 检查挂载目录
.\scripts\init-mounts.ps1 check

# 初始化挂载目录
.\scripts\init-mounts.ps1 init

# 查看详细状态
.\scripts\init-mounts.ps1 status
```

### 3. quick-init.sh
**快速初始化脚本**

功能：
- 一键检查和创建所有挂载目录
- 设置正确的权限
- 提供后续操作指引

使用示例：
```bash
# 在WSL中执行
./scripts/quick-init.sh
```

## 🎯 推荐工作流程

### 首次使用
1. 检查挂载目录：`.\scripts\init-mounts.ps1 check`
2. 初始化挂载目录：`.\scripts\init-mounts.ps1 init`
3. 启动集群：`.\scripts\hadoop-cluster.ps1 start`
4. 查看状态：`.\scripts\hadoop-cluster.ps1 status`

### 日常使用
1. 启动集群：`.\scripts\hadoop-cluster.ps1 start`
2. 使用Web UI访问集群
3. 停止集群：`.\scripts\hadoop-cluster.ps1 stop`

### 故障排查
1. 查看状态：`.\scripts\hadoop-cluster.ps1 status`
2. 查看日志：`.\scripts\hadoop-cluster.ps1 logs master`
3. 测试功能：`.\scripts\hadoop-cluster.ps1 test`

## 🌐 Web UI 访问地址

- **NameNode**: http://localhost:9870
- **ResourceManager**: http://localhost:8088
- **NodeManager1**: http://localhost:8042
- **NodeManager2**: http://localhost:8043

## 📁 挂载目录结构

所有数据挂载在 `/tmp/hadoop-volumes/` 目录下：
- `/tmp/hadoop-volumes/namenode` - NameNode数据
- `/tmp/hadoop-volumes/datanode1` - DataNode1数据
- `/tmp/hadoop-volumes/datanode2` - DataNode2数据
- `/tmp/hadoop-volumes/yarnlogs` - YARN日志

## ⚠️ 注意事项

1. **数据持久化**：挂载目录中的数据会持久保存，重启集群不会丢失
2. **清理数据**：使用 `clean` 命令会删除所有数据，请谨慎操作
3. **权限问题**：确保脚本有执行权限（已自动设置）
4. **WSL路径**：所有WSL操作都在 `/home/docker-compose/hadoop` 目录下进行

## 🔧 故障排除

### 挂载目录不存在
```powershell
# 使用快速初始化
.\scripts\init-mounts.ps1 init

# 或手动创建
wsl -e bash -cl "mkdir -p /tmp/hadoop-volumes/{namenode,datanode1,datanode2,yarnlogs}"
```

### 集群启动失败
1. 检查Docker服务是否运行
2. 检查端口是否被占用
3. 查看详细日志：`.\scripts\hadoop-cluster.ps1 logs`

### WSL环境问题
```powershell
# 检查WSL状态
wsl --status

# 重启WSL
wsl --shutdown
wsl
```

## 📚 更多命令

### Docker命令（在WSL中执行）
```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs master
docker-compose logs worker1

# 进入容器
docker exec -it master bash
docker exec -it worker1 bash
```

### Hadoop命令（在容器中执行）
```bash
# 查看HDFS状态
hdfs dfsadmin -report

# 查看YARN节点
yarn node -list

# 运行示例程序
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 5
```