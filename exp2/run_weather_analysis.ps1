# 天气数据分析MapReduce任务执行脚本
# 功能：找出每个月的最高温度

Write-Host "==========================================" -ForegroundColor Green
Write-Host "天气数据分析MapReduce任务执行脚本" -ForegroundColor Green
Write-Host "功能：找出每个月的最高温度" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# 检查参数
if ($args.Count -ne 1) {
    Write-Host "用法: .\run_weather_analysis.ps1 <输出目录>" -ForegroundColor Red
    Write-Host "示例: .\run_weather_analysis.ps1 /output/weather2024" -ForegroundColor Yellow
    exit 1
}

$OUTPUT_DIR = $args[0]
$INPUT_FILE = "/input/weather.txt"
$JAR_FILE = "weather-analysis.jar"
$DRIVER_CLASS = "WeatherDriver"

Write-Host "输入文件: $INPUT_FILE" -ForegroundColor Cyan
Write-Host "输出目录: $OUTPUT_DIR" -ForegroundColor Cyan
Write-Host "JAR文件: $JAR_FILE" -ForegroundColor Cyan
Write-Host "主类: $DRIVER_CLASS" -ForegroundColor Cyan

# 检查Hadoop集群状态
Write-Host "检查Hadoop集群状态..." -ForegroundColor Yellow
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfsadmin -report" | Select-Object -First 10

if ($LASTEXITCODE -ne 0) {
    Write-Host "Hadoop集群未正常运行！" -ForegroundColor Red
    exit 1
}

# 检查输入文件是否存在
Write-Host "检查输入文件..." -ForegroundColor Yellow
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -test -e $INPUT_FILE"

if ($LASTEXITCODE -ne 0) {
    Write-Host "输入文件不存在，正在上传..." -ForegroundColor Yellow
    wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -mkdir -p /input"
    wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -put /home/exp2/weather.txt $INPUT_FILE"
} else {
    Write-Host "输入文件已存在" -ForegroundColor Green
}

# 清理输出目录（如果存在）
Write-Host "清理输出目录..." -ForegroundColor Yellow
wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -test -d $OUTPUT_DIR"
if ($LASTEXITCODE -eq 0) {
    wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -rm -r $OUTPUT_DIR"
    Write-Host "已删除已存在的输出目录" -ForegroundColor Green
}

# 执行MapReduce任务
Write-Host "开始执行MapReduce任务..." -ForegroundColor Green
Write-Host "执行命令: hadoop jar $JAR_FILE $DRIVER_CLASS $INPUT_FILE $OUTPUT_DIR" -ForegroundColor Cyan

wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master bash -c 'cd /home/exp2 && hadoop jar $JAR_FILE $DRIVER_CLASS $INPUT_FILE $OUTPUT_DIR'" > weather_result.log 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "MapReduce任务执行成功！" -ForegroundColor Green
    Write-Host "日志已保存到: weather_result.log" -ForegroundColor Green
} else {
    Write-Host "MapReduce任务执行失败！" -ForegroundColor Red
    Write-Host "请查看日志文件: weather_result.log" -ForegroundColor Red
    exit 1
}

# 显示结果
Write-Host "显示执行结果..." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "每个月的最高温度：" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

wsl -e bash -cl "cd /home/docker-compose/hadoop && docker exec master hdfs dfs -cat $OUTPUT_DIR/part-r-*" | Select-Object -First 20

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "任务执行完成！" -ForegroundColor Green
Write-Host "完整结果保存在HDFS: $OUTPUT_DIR" -ForegroundColor Green
Write-Host "执行日志保存在本地: weather_result.log" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan