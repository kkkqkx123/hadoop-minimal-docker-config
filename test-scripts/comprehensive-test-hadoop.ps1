# Hadoop Comprehensive Test Script (PowerShell Version)

Write-Host "=== Hadoop Cluster Comprehensive Test ===" -ForegroundColor Cyan

# Test functions
function Test-Passed {
    param($Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Test-Failed {
    param($Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Test-Warning {
    param($Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Test-Info {
    param($Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

# Test results summary
$testResults = @()

# 1. Check container status
Write-Host "1. Checking container status..."
$dockerPs = docker-compose ps
if ($dockerPs -match "Up") {
    Test-Passed "Containers running normally"
    $testResults += "Container Status: PASS"
} else {
    Test-Failed "Containers not running normally"
    $testResults += "Container Status: FAIL"
    exit 1
}

# 2. Check Web UI ports
Write-Host "2. Checking Web UI ports..."
function Check-Port {
    param($Port, $Name)
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Test-Passed "$Name Web UI normal (port: $Port)"
            $script:testResults += "$Name Web UI: PASS"
        } else {
            Test-Warning "$Name Web UI not accessible (port: $Port)"
            $script:testResults += "$Name Web UI: WARNING"
        }
    } catch {
        Test-Warning "$Name Web UI not accessible (port: $Port)"
        $script:testResults += "$Name Web UI: FAIL"
    }
}

Check-Port -Port 9870 -Name "NameNode"
Check-Port -Port 8088 -Name "ResourceManager"

# 3. Check HDFS status
Write-Host "3. Checking HDFS status..."
$hdfsReport = docker exec master hdfs dfsadmin -report
if ($hdfsReport -match "Live datanodes") {
    $datanodes = ($hdfsReport | Select-String "Live datanodes").ToString().Split(' ')[2]
    Test-Passed "HDFS normal - DataNode count: $datanodes"
    $testResults += "HDFS Status: PASS ($datanodes DataNodes)"
} else {
    Test-Failed "HDFS status abnormal"
    $testResults += "HDFS Status: FAIL"
}

# 4. Check YARN status
Write-Host "4. Checking YARN status..."
$yarnNodes = docker exec master yarn node -list
if ($yarnNodes -match "RUNNING") {
    $nodeManagers = ($yarnNodes | Select-String "RUNNING").Count
    Test-Passed "YARN normal - NodeManager count: $nodeManagers"
    $testResults += "YARN Status: PASS ($nodeManagers NodeManagers)"
} else {
    Test-Failed "YARN status abnormal"
    $testResults += "YARN Status: FAIL"
}

# 5. File operations test
Write-Host "5. Testing HDFS file operations..."
docker exec master bash -c "echo test data > /tmp/test.txt"
docker exec master bash -c "hdfs dfs -mkdir -p /test"
docker exec master bash -c "hdfs dfs -put /tmp/test.txt /test/"
docker exec master bash -c "hdfs dfs -cat /test/test.txt"
docker exec master bash -c "hdfs dfs -rm /test/test.txt"
docker exec master bash -c "hdfs dfs -rmdir /test"

if ($LASTEXITCODE -eq 0) {
    Test-Passed "HDFS file operations normal"
    $testResults += "HDFS File Operations: PASS"
} else {
    Test-Failed "HDFS file operations failed"
    $testResults += "HDFS File Operations: FAIL"
}

# 6. MapReduce test
Write-Host "6. Testing MapReduce job..."
Test-Info "Creating test data..."
docker exec master bash -c "echo -e 'hello world\nhello hadoop\nworld of hadoop' > /tmp/wordcount_input.txt"

docker exec master bash -c "hdfs dfs -mkdir -p /user/hadoop/input"
docker exec master bash -c "hdfs dfs -put /tmp/wordcount_input.txt /user/hadoop/input/"

docker exec master bash -c "cd /opt/hadoop && hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount /user/hadoop/input /user/hadoop/output"

if ($LASTEXITCODE -eq 0) {
    Test-Passed "MapReduce job completed successfully"
    $testResults += "MapReduce Job: PASS"
    
    Test-Info "Checking results..."
    $results = docker exec master bash -c "hdfs dfs -cat /user/hadoop/output/part-r-*"
    if ($results -match "hello" -and $results -match "world" -and $results -match "hadoop") {
        Test-Passed "WordCount results correct"
        $testResults += "WordCount Results: PASS"
    } else {
        Test-Warning "WordCount results may be incomplete"
        $testResults += "WordCount Results: WARNING"
    }
    
    # Cleanup
    docker exec master bash -c "hdfs dfs -rm -r /user/hadoop/output"
    docker exec master bash -c "hdfs dfs -rm /user/hadoop/input/wordcount_input.txt"
    docker exec master bash -c "hdfs dfs -rmdir /user/hadoop/input"
} else {
    Test-Failed "MapReduce job failed"
    $testResults += "MapReduce Job: FAIL"
}

# 7. Cluster health check
Write-Host "7. Checking cluster health..."
$healthCheck = docker exec master hdfs dfsadmin -report | Select-String "Heap Memory Used"
if ($healthCheck) {
    Test-Info "Cluster health: $healthCheck"
    $testResults += "Cluster Health: CHECKED"
} else {
    Test-Warning "Could not retrieve cluster health info"
    $testResults += "Cluster Health: WARNING"
}

# Summary
Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
foreach ($result in $testResults) {
    if ($result -match "PASS") {
        Write-Host "✓ $result" -ForegroundColor Green
    } elseif ($result -match "FAIL") {
        Write-Host "✗ $result" -ForegroundColor Red
    } else {
        Write-Host "⚠ $result" -ForegroundColor Yellow
    }
}

$passCount = ($testResults | Where-Object { $_ -match "PASS" }).Count
$failCount = ($testResults | Where-Object { $_ -match "FAIL" }).Count
$warningCount = ($testResults | Where-Object { $_ -match "WARNING" }).Count

Write-Host ""
Write-Host "=== Final Results ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Count)"
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "Warnings: $warningCount" -ForegroundColor Yellow

if ($failCount -eq 0) {
    Write-Host "🎉 Hadoop cluster is running normally!" -ForegroundColor Green
} else {
    Write-Host "❌ Some tests failed. Please check the cluster." -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Comprehensive test completed ===" -ForegroundColor Cyan