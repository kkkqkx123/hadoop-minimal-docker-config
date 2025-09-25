# Alpine Linux OpenJDK 11 版本的JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# JVM性能优化参数
export HADOOP_HEAPSIZE_MAX=512
export HADOOP_HEAPSIZE_MIN=256
export HADOOP_OPTS="$HADOOP_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions"

# NameNode JVM参数
export HADOOP_NAMENODE_OPTS="-Xmx384m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 $HADOOP_NAMENODE_OPTS"

# DataNode JVM参数  
export HADOOP_DATANODE_OPTS="-Xmx256m -Xms128m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 $HADOOP_DATANODE_OPTS"

# ResourceManager JVM参数
export YARN_RESOURCEMANAGER_OPTS="-Xmx384m -Xms256m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 $YARN_RESOURCEMANAGER_OPTS"

# NodeManager JVM参数
export YARN_NODEMANAGER_OPTS="-Xmx256m -Xms128m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 $YARN_NODEMANAGER_OPTS"