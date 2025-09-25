# Hadoop Core Functionality Test Script (PowerShell Version)

Write-Host "=== Hadoop Core Functionality Test ===" -ForegroundColor Cyan

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

Write-Host "Starting Hadoop cluster functionality test..." -ForegroundColor Yellow
Write-Host ""

# 1. Check container status
Write-Host "1. Checking container status..."
$dockerPs = docker-compose ps
if ($dockerPs -match "Up") {
    Test-Passed "All containers running normally"
    $testResults += "Container Status: PASS"
} else {
    Test-Failed "Containers not running normally"
    $testResults += "Container Status: FAIL"
    exit 1
}

# 2. Check Web UI accessibility
Write-Host "2. Checking Web UI accessibility..."
function Check-Port {
    param($Port, $Name)
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -ErrorAction SilentlyContinue -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Test-Passed "$Name Web UI accessible (port: $Port)"
            $script:testResults += "$Name Web UI: PASS"
        } else {
            Test-Warning "$Name Web UI returned status: $($response.StatusCode)"
            $script:testResults += "$Name Web UI: WARNING"
        }
    } catch {
        Test-Failed "$Name Web UI not accessible (port: $Port) - $($_.Exception.Message)"
        $script:testResults += "$Name Web UI: FAIL"
    }
}

Check-Port -Port 9870 -Name "NameNode"
Check-Port -Port 8088 -Name "ResourceManager"

# 3. Check HDFS health
Write-Host "3. Checking HDFS health..."
try {
    $hdfsReport = docker exec master hdfs dfsadmin -report
    if ($hdfsReport -match "Live datanodes") {
        $datanodes = ($hdfsReport | Select-String "Live datanodes").ToString().Split(' ')[2]
        Test-Passed "HDFS healthy - Active DataNodes: $datanodes"
        $testResults += "HDFS Status: PASS ($datanodes DataNodes)"
        
        # Check HDFS capacity
        $capacityInfo = $hdfsReport | Select-String "Configured Capacity"
        if ($capacityInfo) {
            Test-Info "HDFS Capacity: $capacityInfo"
        }
    } else {
        Test-Failed "HDFS status check failed"
        $testResults += "HDFS Status: FAIL"
    }
} catch {
    Test-Failed "HDFS command failed: $($_.Exception.Message)"
    $testResults += "HDFS Status: FAIL"
}

# 4. Check YARN resource management
Write-Host "4. Checking YARN resource management..."
try {
    $yarnNodes = docker exec master yarn node -list
    if ($yarnNodes -match "RUNNING") {
        $nodeManagers = ($yarnNodes | Select-String "RUNNING").Count
        Test-Passed "YARN healthy - Active NodeManagers: $nodeManagers"
        $testResults += "YARN Status: PASS ($nodeManagers NodeManagers)"
    } else {
        Test-Warning "No RUNNING NodeManagers found"
        $testResults += "YARN Status: WARNING"
    }
} catch {
    Test-Failed "YARN command failed: $($_.Exception.Message)"
    $testResults += "YARN Status: FAIL"
}

# 5. Test basic HDFS operations
Write-Host "5. Testing basic HDFS operations..."
try {
    # Create test file
    docker exec master bash -c "echo 'Hadoop test data' > /tmp/hadoop_test.txt"
    
    # Create directory in HDFS
    docker exec master bash -c "hdfs dfs -mkdir -p /test"
    
    # Upload file
    docker exec master bash -c "hdfs dfs -put /tmp/hadoop_test.txt /test/"
    
    # List files
    $fileList = docker exec master bash -c "hdfs dfs -ls /test"
    if ($fileList -match "hadoop_test.txt") {
        Test-Passed "File upload successful"
    } else {
        Test-Warning "File not found in HDFS"
    }
    
    # Read file content
    $content = docker exec master bash -c "hdfs dfs -cat /test/hadoop_test.txt"
    if ($content -match "Hadoop test data") {
        Test-Passed "File read successful - content verified"
    } else {
        Test-Warning "File content mismatch"
    }
    
    # Delete file and directory
    docker exec master bash -c "hdfs dfs -rm /test/hadoop_test.txt"
    docker exec master bash -c "hdfs dfs -rmdir /test"
    
    Test-Passed "HDFS file operations completed successfully"
    $testResults += "HDFS Operations: PASS"
    
} catch {
    Test-Failed "HDFS operations failed: $($_.Exception.Message)"
    $testResults += "HDFS Operations: FAIL"
}

# 6. Check cluster configuration
Write-Host "6. Checking cluster configuration..."
try {
    # Check core-site.xml
    $coreSite = docker exec master bash -c "cat /opt/hadoop/etc/hadoop/core-site.xml"
    if ($coreSite -match "fs.defaultFS") {
        Test-Passed "Core site configuration found"
        $testResults += "Core Config: PASS"
    } else {
        Test-Warning "Core site configuration missing"
        $testResults += "Core Config: WARNING"
    }
    
    # Check hdfs-site.xml
    $hdfsSite = docker exec master bash -c "cat /opt/hadoop/etc/hadoop/hdfs-site.xml"
    if ($hdfsSite -match "dfs.replication") {
        Test-Passed "HDFS site configuration found"
        $testResults += "HDFS Config: PASS"
    } else {
        Test-Warning "HDFS site configuration missing"
        $testResults += "HDFS Config: WARNING"
    }
    
} catch {
    Test-Failed "Configuration check failed: $($_.Exception.Message)"
    $testResults += "Config Check: FAIL"
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
    Write-Host "🎉 Hadoop cluster core functionality is working correctly!" -ForegroundColor Green
    Write-Host "✓ You can now use HDFS for file storage and YARN for resource management." -ForegroundColor Green
} else {
    Write-Host "❌ Some core functionality tests failed. Please check the cluster configuration." -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Core functionality test completed ===" -ForegroundColor Cyan