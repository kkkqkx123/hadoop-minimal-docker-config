我已经成功修复了Hadoop YARN集群的问题！主要解决了以下问题：

### 🔧 问题诊断与修复
1. ResourceManager启动失败 - 根本原因是缺少容量调度器配置
2. 创建容量调度器配置文件 - 在 conf/capacity-scheduler.xml 中配置了根队列和默认队列
3. 配置YARN调度器类 - 在 yarn-site.xml 中明确指定了 CapacityScheduler 类
4. 修复MapReduce环境变量 - 在 mapred-site.xml 中添加了 HADOOP_MAPRED_HOME 环境变量配置
### ✅ 当前状态
- ResourceManager : ✓ 正常运行 (端口8032)
- NodeManager : ✓ 两个工作节点都正常运行
- HDFS : ✓ NameNode、DataNode、SecondaryNameNode全部正常
- JobHistoryServer : ✓ 正常运行
- MapReduce作业 : ✓ 成功执行，计算了π值
### 🎯 验证结果
MapReduce作业成功完成，输出显示：

- 作业ID: job_1761017079869_0002
- 运行时间: 42.169秒
- 估算的π值: 3.6
- 2个map任务和1个reduce任务成功执行
YARN集群现在完全正常运行，可以处理MapReduce作业了！