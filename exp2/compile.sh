#!/bin/bash

cd /home/docker-compose/hadoop/exp2

# 设置Hadoop类路径
export HADOOP_CLASSPATH=$(hadoop classpath)
echo "Hadoop classpath: $HADOOP_CLASSPATH"

# 编译Java代码
echo "Compiling Java files..."
javac -cp "$HADOOP_CLASSPATH" *.java

if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    
    # 创建JAR包
    echo "Creating JAR file..."
    jar cf invertedindex.jar *.class
    
    if [ $? -eq 0 ]; then
        echo "JAR file created successfully!"
        ls -la *.jar
    else
        echo "Failed to create JAR file!"
        exit 1
    fi
else
    echo "Compilation failed!"
    exit 1
fi