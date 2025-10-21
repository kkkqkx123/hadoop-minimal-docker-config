org.apache.hadoop.yarn.exceptions.InvalidResourceRequestException: Invalid resource request! Cannot allocate containers as requested resource is greater than maximum allowed allocation. Requested resource type=[memory-mb], Requested resource=<memory:1536, vCores:1>, maximum allowed allocation=<memory:1024, vCores:1>, please note that maximum allowed allocation is calculated by scheduler based on maximum resource of registered NodeManagers, which might be less than configured maximum allocation=<memory:1024, vCores:1>
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.throwInvalidResourceException(SchedulerUtils.java:525)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.checkResourceRequestAgainstAvailableResource(SchedulerUtils.java:421)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.validateResourceRequest(SchedulerUtils.java:349)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.normalizeAndValidateRequest(SchedulerUtils.java:304)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.validateAndCreateResourceRequest(RMAppManager.java:624)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.createAndPopulateNewRMApp(RMAppManager.java:450)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.submitApplication(RMAppManager.java:373)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.ClientRMService.submitApplication(ClientRMService.java:687)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.api.impl.pb.service.ApplicationClientProtocolPBServiceImpl.submitApplication(ApplicationClientProtocolPBServiceImpl.java:290)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.proto.ApplicationClientProtocol$ApplicationClientProtocolService$2.callBlockingMethod(ApplicationClientProtocol.java:617)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.ProtobufRpcEngine2$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine2.java:621)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.ProtobufRpcEngine2$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine2.java:589)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.ProtobufRpcEngine2$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine2.java:573)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:1227)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:1094)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:1017)
2025-09-25 20:16:33.593 | 	at java.base/java.security.AccessController.doPrivileged(Native Method)
2025-09-25 20:16:33.593 | 	at java.base/javax.security.auth.Subject.doAs(Subject.java:423)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1899)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.Server$Handler.run(Server.java:3048)
2025-09-25 20:16:33.593 | 2025-09-25 12:16:32,637 INFO org.apache.hadoop.yarn.server.resourcemanager.ClientRMService: Exception in submitting application_1758800964609_0002
2025-09-25 20:16:33.593 | org.apache.hadoop.yarn.exceptions.InvalidResourceRequestException: Invalid resource request! Cannot allocate containers as requested resource is greater than maximum allowed allocation. Requested resource type=[memory-mb], Requested resource=<memory:1536, vCores:1>, maximum allowed allocation=<memory:1024, vCores:1>, please note that maximum allowed allocation is calculated by scheduler based on maximum resource of registered NodeManagers, which might be less than configured maximum allocation=<memory:1024, vCores:1>
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.throwInvalidResourceException(SchedulerUtils.java:525)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.checkResourceRequestAgainstAvailableResource(SchedulerUtils.java:421)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.validateResourceRequest(SchedulerUtils.java:349)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.normalizeAndValidateRequest(SchedulerUtils.java:304)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.validateAndCreateResourceRequest(RMAppManager.java:624)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.createAndPopulateNewRMApp(RMAppManager.java:450)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.submitApplication(RMAppManager.java:373)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.ClientRMService.submitApplication(ClientRMService.java:687)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.api.impl.pb.service.ApplicationClientProtocolPBServiceImpl.submitApplication(ApplicationClientProtocolPBServiceImpl.java:290)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.proto.ApplicationClientProtocol$ApplicationClientProtocolService$2.callBlockingMethod(ApplicationClientProtocol.java:617)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.ProtobufRpcEngine2$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine2.java:621)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.ProtobufRpcEngine2$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine2.java:589)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.ProtobufRpcEngine2$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine2.java:573)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:1227)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:1094)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:1017)
2025-09-25 20:16:33.593 | 	at java.base/java.security.AccessController.doPrivileged(Native Method)
2025-09-25 20:16:33.593 | 	at java.base/javax.security.auth.Subject.doAs(Subject.java:423)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1899)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.Server$Handler.run(Server.java:3048)
2025-09-25 20:16:33.593 | 2025-09-25 12:16:32,637 INFO org.apache.hadoop.ipc.Server: IPC Server handler 44 on default port 8032, call Call#38 Retry#0 org.apache.hadoop.yarn.api.ApplicationClientProtocolPB.submitApplication from master:58200 / 172.18.0.4:58200
2025-09-25 20:16:33.593 | org.apache.hadoop.yarn.exceptions.InvalidResourceRequestException: Invalid resource request! Cannot allocate containers as requested resource is greater than maximum allowed allocation. Requested resource type=[memory-mb], Requested resource=<memory:1536, vCores:1>, maximum allowed allocation=<memory:1024, vCores:1>, please note that maximum allowed allocation is calculated by scheduler based on maximum resource of registered NodeManagers, which might be less than configured maximum allocation=<memory:1024, vCores:1>
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.throwInvalidResourceException(SchedulerUtils.java:525)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.checkResourceRequestAgainstAvailableResource(SchedulerUtils.java:421)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.validateResourceRequest(SchedulerUtils.java:349)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.normalizeAndValidateRequest(SchedulerUtils.java:304)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.validateAndCreateResourceRequest(RMAppManager.java:624)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.createAndPopulateNewRMApp(RMAppManager.java:450)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.RMAppManager.submitApplication(RMAppManager.java:373)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.server.resourcemanager.ClientRMService.submitApplication(ClientRMService.java:687)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.api.impl.pb.service.ApplicationClientProtocolPBServiceImpl.submitApplication(ApplicationClientProtocolPBServiceImpl.java:290)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.yarn.proto.ApplicationClientProtocol$ApplicationClientProtocolService$2.callBlockingMethod(ApplicationClientProtocol.java:617)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.ProtobufRpcEngine2$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine2.java:621)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.ProtobufRpcEngine2$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine2.java:589)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.ProtobufRpcEngine2$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine2.java:573)
2025-09-25 20:16:33.593 | 	at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:1227)
2025-09-25 20:16:33.594 | 	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:1094)
2025-09-25 20:16:33.594 | 	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:1017)
2025-09-25 20:16:33.594 | 	at java.base/java.security.AccessController.doPrivileged(Native Method)
2025-09-25 20:16:33.594 | 	at java.base/javax.security.auth.Subject.doAs(Subject.java:423)
2025-09-25 20:16:33.594 | 	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1899)
2025-09-25 20:16:33.594 | 	at org.apache.hadoop.ipc.Server$Handler.run(Server.java:3048)


---
解决：
**降低 YARN 请求资源**是最直接、轻量的解决方式，尤其适合测试/学习环境。你只需**调低 MapReduce/YARN 默认任务内存**，无需改动容器或宿主机资源。

---

### ✅ 目标
让 YARN 应用默认请求 **≤1024 MB**，避免触发 `InvalidResourceRequestException`。

---

### 🔧 修改方法（3 步）

#### 1. 修改 `mapred-site.xml`
打开：
<mcfile name="mapred-site.xml" path="d:\项目\docker-compose\hadoop\conf\mapred-site.xml"></mcfile>

加入或更新以下配置（**单位是 MB**）：

```xml
<property>
  <name>mapreduce.map.memory.mb</name>
  <value>512</value>
</property>
<property>
  <name>mapreduce.reduce.memory.mb</name>
  <value>512</value>
</property>
<property>
  <name>mapreduce.map.java.opts</name>
  <value>-Xmx400m</value>
</property>
<property>
  <name>mapreduce.reduce.java.opts</name>
  <value>-Xmx400m</value>
</property>
```

#### 2. 修改 `yarn-site.xml`
打开：
<mcfile name="yarn-site.xml" path="d:\项目\docker-compose\hadoop\conf\yarn-site.xml"></mcfile>

确保以下值 **≤1024**（已符合）：

```xml
<property>
  <name>yarn.scheduler.maximum-allocation-mb</name>
  <value>1024</value>
</property>
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>1024</value>
</property>
```

#### 3. 同步配置到 WSL 并重启
```powershell
wsl.exe cp /mnt/d/项目/docker-compose/hadoop/conf/mapred-site.xml ${WSL_TARGET}/conf/
wsl.exe cp /mnt/d/项目/docker-compose/hadoop/conf/yarn-site.xml ${WSL_TARGET}/conf/
wsl -e bash -cl "cd ${WSL_TARGET} && docker-compose restart"
```

---

### ✅ 验证
提交一个示例 MapReduce 任务（如 `pi`）：

```bash
docker-compose exec master hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi 2 10
```

- 若任务成功且日志中 **不再出现 `Requested resource=<memory:1536`**，说明已生效。
- 若仍失败，检查日志确认请求内存是否已降到 512/1024 MB。

---

### ✅ 总结
| 方案 | 改动点 | 适用场景 |
|---|---|---|
| **降低任务内存**（推荐） | 修改 `mapred-site.xml` | 测试/学习，资源最小化 |
| 提高 YARN 上限 | 修改 `yarn-site.xml` + 容器内存 | 生产/高负载 |

你当前场景 **选降低任务内存即可**，无需扩容容器。
