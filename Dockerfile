FROM openjdk:11-slim

ARG HADOOP_VERSION=3.3.6
ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

# 基础工具与 SSH（精简版本）
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openssh-server rsync curl ca-certificates procps python3 && \
    rm -rf /var/lib/apt/lists/*

# Hadoop
RUN curl -fsSL https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
     -o /tmp/hadoop.tgz && \
    mkdir -p /opt && \
    tar -xzf /tmp/hadoop.tgz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm /tmp/hadoop.tgz

# 数据目录
RUN mkdir -p /hadoop/dfs/namenode /hadoop/dfs/datanode /tmp/hadoop-yarn && \
    mkdir -p ${HADOOP_HOME}/logs

# SSH 配置（演示用：镜像内置同一套 root key）
RUN mkdir -p /var/run/sshd /root/.ssh && \
    ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys && \
    printf "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n" > /root/.ssh/config && \
    sed -ri 's/#?PermitRootLogin .*/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config && \
    sed -ri 's/#?PasswordAuthentication .*/PasswordAuthentication no/g' /etc/ssh/sshd_config

# 安装dos2unix用于文件格式转换
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends dos2unix && \
    rm -rf /var/lib/apt/lists/*

# 拷贝配置与脚本
COPY conf/core-site.xml ${HADOOP_HOME}/etc/hadoop/core-site.xml
COPY conf/hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
COPY conf/yarn-site.xml ${HADOOP_HOME}/etc/hadoop/yarn-site.xml
COPY conf/mapred-site.xml ${HADOOP_HOME}/etc/hadoop/mapred-site.xml
COPY conf/hadoop-env.sh ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
COPY conf/workers ${HADOOP_HOME}/etc/hadoop/workers

# 转换配置文件为Unix格式
RUN dos2unix ${HADOOP_HOME}/etc/hadoop/*.xml ${HADOOP_HOME}/etc/hadoop/*.sh ${HADOOP_HOME}/etc/hadoop/workers

COPY scripts/entrypoint-pseudo.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && dos2unix /usr/local/bin/entrypoint.sh

# 暴露常用端口（compose 里会映射）
EXPOSE 22 8020 9870 9864 8088 8042 19888 10020

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]