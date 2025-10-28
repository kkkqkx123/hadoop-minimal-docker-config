@echo off
echo 学生成绩Top10排序程序测试说明

echo.
echo ===== 重要说明 =====
echo 此程序需要在Hadoop Docker环境中运行。
echo 请按照以下步骤在Docker环境中测试：
echo.
echo 步骤1：启动Hadoop集群
echo     docker-compose up -d
echo.
echo 步骤2：将exp1目录复制到容器中
echo     docker cp exp1 hadoop-master:/opt/hadoop/exp1
echo.
echo 步骤3：进入容器并运行测试
echo     docker exec -it hadoop-master bash
echo     cd /opt/hadoop/exp1
echo     ./run_docker_test.sh
echo.
echo ===== 测试数据预览 =====
echo.
echo 测试数据1（高分段）：
type test_data1.txt
echo.
echo 预期输出1：
type expected_output1.txt
echo.
echo 测试数据2（中分段）：
type test_data2.txt
echo.
echo 测试数据3（超高分段）：
type test_data3.txt
echo.
echo 原始数据集：
type dataset\top10input.txt
echo.
echo ===== 程序文件列表 =====
dir /b *.java
echo.
echo 编译后的JAR包：top10.jar
echo.
echo 请按照上述说明在Docker环境中运行测试。