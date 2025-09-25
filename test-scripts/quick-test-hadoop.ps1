# Hadoop Quick Test Script (PowerShell Version)

Write-Host "=== Hadoop Cluster Quick Test ===" -ForegroundColor Cyan

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

# 1. Check container status
Write-Host "1. Checking container status..."
$dockerPs = docker-compose ps
if ($dockerPs -match "Up") {
    Test-Passed "Containers running normally"
} else {
    Test-Failed "Containers not running normally"
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
        } else {
            Test-Warning "$Name Web UI not accessible (port: $Port)"
        }
    } catch {
        Test-Warning "$Name Web UI not accessible (port: $Port)"
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
} else {
    Test-Failed "HDFS status abnormal"
}

# 4. Check YARN status
Write-Host "4. Checking YARN status..."
$yarnNodes = docker exec master yarn node -list
if ($yarnNodes -match "RUNNING") {
    $nodeManagers = ($yarnNodes | Select-String "RUNNING").Count
    Test-Passed "YARN normal - NodeManager count: $nodeManagers"
} else {
    Test-Failed "YARN status abnormal"
}

# 5. Simple file operation test
Write-Host "5. File operation test..."
docker exec master bash -c "echo test data > /tmp/test.txt"
docker exec master bash -c "hdfs dfs -mkdir -p /test"
docker exec master bash -c "hdfs dfs -put /tmp/test.txt /test/"
docker exec master bash -c "hdfs dfs -cat /test/test.txt"
docker exec master bash -c "hdfs dfs -rm /test/test.txt"
docker exec master bash -c "hdfs dfs -rmdir /test"

if ($LASTEXITCODE -eq 0) {
    Test-Passed "HDFS file operations normal"
} else {
    Test-Failed "HDFS file operations failed"
}

Write-Host ""
Write-Host "=== Quick test completed ===" -ForegroundColor Cyan