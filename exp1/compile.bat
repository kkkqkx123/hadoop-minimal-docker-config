@echo off
echo 编译学生成绩Top10排序程序...

REM 在Docker环境中，Hadoop类路径在容器内部设置
REM 这里我们只编译Java文件，运行时在Docker容器内执行

REM 编译Java文件
echo 编译Java源文件...
javac -cp "." -d . *.java

if %errorlevel% neq 0 (
    echo 编译失败！
    exit /b 1
)

echo 编译成功！

REM 创建JAR包
echo 创建JAR包...
jar cf top10.jar *.class

if %errorlevel% neq 0 (
    echo JAR包创建失败！
    exit /b 1
)

echo JAR包创建成功：top10.jar

REM 清理class文件
echo 清理临时文件...
del *.class

echo 编译完成！
echo.
echo 注意：此程序需要在Hadoop Docker环境中运行