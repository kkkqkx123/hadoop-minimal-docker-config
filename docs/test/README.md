# Hadoop集群测试文档目录

本目录包含Docker部署的Hadoop集群功能测试相关文档。

## 📋 文档列表

### 1. [Hadoop功能测试指南](hadoop-functionality-test-guide.md)
完整的Hadoop集群功能测试指南，包含：
- 环境准备和检查
- HDFS功能测试
- YARN功能测试
- MapReduce作业测试
- 性能基准测试
- 故障排查指南

### 2. [快速测试脚本](quick-test-script.md)
一键快速测试脚本，包含：
- 自动化测试脚本
- 快速验证方法
- 常见问题快速排查
- 测试结果解读

### 3. [测试清单](test-checklist.md)
系统化测试清单，包含：
- 逐项测试检查点
- Web UI访问验证
- 命令行操作验证
- 测试结果记录模板

### 4. 测试脚本目录 (`scripts/`)
自动化测试脚本集合，包含：
- `run-all-tests.sh` - 一键测试主脚本（推荐）
- `quick-test-hadoop.sh` - 快速功能测试
- `test-hdfs.sh` - HDFS详细测试
- `test-yarn.sh` - YARN功能测试
- `test-performance.sh` - 性能基准测试
- `check-cluster-health.sh` - 集群健康检查

## 🚀 快速开始

### 新手入门
1. **环境检查**
   ```bash
   docker ps
   ```

2. **进入master容器**
   ```bash
   docker exec -it master bash
   ```

3. **执行一键测试（推荐）**
   ```bash
   cd /opt/hadoop/docs/test/scripts
   chmod +x *.sh
   ./run-all-tests.sh
   ```

### 详细测试
1. **完整功能测试**: 参考 `hadoop-functionality-test-guide.md`
2. **快速测试脚本**: 参考 `quick-test-script.md`
3. **逐项检查**: 使用 `test-checklist.md`
4. **自动化脚本**: 使用 `scripts/` 目录中的测试脚本

### 测试优先级

| 优先级 | 测试项目 | 预计时间 | 文档位置 |
|--------|----------|----------|----------|
| 🔴 高 | 容器状态检查 | 2分钟 | 测试清单 - 环境检查 |
| 🔴 高 | Web UI访问 | 3分钟 | 测试清单 - Web UI访问测试 |
| 🟡 中 | HDFS基本操作 | 10分钟 | 功能测试指南 - HDFS功能测试 |
| 🟡 中 | YARN作业提交 | 15分钟 | 功能测试指南 - YARN功能测试 |
| 🟢 低 | 性能基准测试 | 30分钟 | 功能测试指南 - 性能基准测试 |

## 📊 测试结果解读

### 快速测试结果

✅ **全部通过**: 集群运行正常，可以投入使用

⚠️ **部分通过**: 基础功能正常，但某些高级功能可能有问题

❌ **未通过**: 集群存在严重问题，需要排查修复

### 常见状态码

| 状态 | 含义 | 处理方式 |
|------|------|----------|
| ✅ | 测试通过 | 无需处理 |
| ⚠️ | 测试警告 | 查看详细日志，评估影响 |
| ❌ | 测试失败 | 按照故障排查指南处理 |
| ⏸️ | 测试跳过 | 手动验证或查看原因 |

## 🛠️ 故障排查工具

### 常用命令

```bash
# 查看容器状态
docker-compose ps

# 查看容器日志
docker-compose logs [service-name]

# 进入容器
docker exec -it [container-name] bash

# 查看Hadoop进程
jps

# 检查HDFS状态
hdfs dfsadmin -report

# 检查YARN状态
yarn node -list
```

### 日志位置

| 组件 | 日志位置 | 查看命令 |
|------|----------|----------|
| NameNode | `$HADOOP_HOME/logs/hadoop-*-namenode-*.log` | `docker exec master tail -f $HADOOP_HOME/logs/*namenode*.log` |
| DataNode | `$HADOOP_HOME/logs/hadoop-*-datanode-*.log` | `docker exec worker1 tail -f $HADOOP_HOME/logs/*datanode*.log` |
| ResourceManager | `$HADOOP_HOME/logs/yarn-*-resourcemanager-*.log` | `docker exec master tail -f $HADOOP_HOME/logs/*resourcemanager*.log` |
| NodeManager | `$HADOOP_HOME/logs/yarn-*-nodemanager-*.log` | `docker exec worker1 tail -f $HADOOP_HOME/logs/*nodemanager*.log` |

## 📞 技术支持

### 常见问题

1. **Web UI无法访问**
   - 检查端口是否被占用
   - 确认防火墙设置
   - 查看 [快速测试脚本](quick-test-script.md) 的故障排查部分

2. **HDFS操作失败**
   - 检查DataNode状态
   - 验证网络连接
   - 查看NameNode和DataNode日志

3. **YARN作业提交失败**
   - 检查资源配额
   - 验证NodeManager状态
   - 查看ResourceManager日志

### 获取帮助

- 查看详细日志信息
- 参考官方Hadoop文档
- 在社区论坛寻求帮助

## 🎯 测试目标

通过本套测试文档，您将能够：

1. ✅ 验证Hadoop集群基本部署成功
2. ✅ 确认HDFS分布式文件系统正常工作
3. ✅ 验证YARN资源管理系统功能完整
4. ✅ 测试MapReduce计算框架运行正常
5. ✅ 评估集群性能和稳定性
6. ✅ 掌握故障排查和问题解决技能

## 📝 版本历史

| 版本 | 日期 | 更新内容 | 作者 |
|------|------|----------|------|
| 1.0 | 2024-01 | 初始版本 | AI助手 |

---

**祝测试顺利！** 🎉

如果所有测试都通过，您的Docker Hadoop集群就已经准备好处理大数据任务了。