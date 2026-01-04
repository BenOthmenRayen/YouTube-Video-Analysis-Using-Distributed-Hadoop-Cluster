# ============================================
# MASTER SETUP SCRIPT
# Complete YouTube Video Analysis Project
# ============================================

$ErrorActionPreference = "Continue"

Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     YOUTUBE VIDEO ANALYSIS - HADOOP CLUSTER              ║
║     Complete Automated Setup                             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host ""

if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "ERROR: docker-compose.yml not found!" -ForegroundColor Red
    exit 1
}

Write-Host "STEP 1: Fixing environment configuration..." -ForegroundColor Yellow
if (Test-Path .env) { Remove-Item .env -Force }

@"
YOUTUBE_API_KEY=AIzaSyBHluThwJrFDPSHNyE5U0jt-F-FFJl0LZ4
CORE_CONF_fs_defaultFS=hdfs://namenode:9000
HDFS_CONF_dfs_replication=3
YARN_CONF_yarn_nodemanager_resource_memory_mb=4096
"@ | Out-File -FilePath .env -Encoding UTF8 -NoNewline

Write-Host "✓ Created new .env file" -ForegroundColor Green
Write-Host ""

Write-Host "STEP 2: Cleaning existing cluster..." -ForegroundColor Yellow
docker-compose down -v 2>$null | Out-Null
Write-Host "✓ Cleaned" -ForegroundColor Green
Write-Host ""

Write-Host "STEP 3: Creating project structure..." -ForegroundColor Yellow
if (-not (Test-Path "youtube-api")) {
    New-Item -ItemType Directory -Force -Path "youtube-api" | Out-Null
}
Write-Host "✓ Structure ready" -ForegroundColor Green
Write-Host ""

Write-Host "STEP 4: Starting Hadoop cluster..." -ForegroundColor Yellow
docker-compose up -d
Write-Host "✓ Cluster started" -ForegroundColor Green
Write-Host ""

Write-Host "STEP 5: Waiting for initialization (2 minutes)..." -ForegroundColor Yellow
for ($i = 120; $i -gt 0; $i--) {
    Write-Progress -Activity "Initializing" -Status "Time: $i seconds" -PercentComplete ((120-$i)/120*100)
    Start-Sleep -Seconds 1
}
Write-Host "✓ Initialization complete" -ForegroundColor Green
Write-Host ""

Write-Host "STEP 6: Verifying cluster..." -ForegroundColor Yellow
$running = docker-compose ps --services --filter "status=running" | Measure-Object
Write-Host "  Running containers: $($running.Count)" -ForegroundColor White

$yarn_output = docker exec resourcemanager yarn node -list 2>$null
if ($yarn_output -match "Total Nodes:3") {
    Write-Host "✓ YARN: 3 nodes running" -ForegroundColor Green
}
Write-Host ""

Write-Host "STEP 7: Creating HDFS directories..." -ForegroundColor Yellow
$directories = @("/youtube", "/youtube/videos", "/youtube/metadata", "/youtube/analysis", "/youtube/results")
foreach ($dir in $directories) {
    docker exec namenode hdfs dfs -mkdir -p $dir 2>$null | Out-Null
}
docker exec namenode hdfs dfs -chmod -R 777 /youtube 2>$null | Out-Null
Write-Host "✓ HDFS directories created" -ForegroundColor Green
Write-Host ""

Write-Host "STEP 8: Building YouTube fetcher..." -ForegroundColor Yellow
if (Test-Path "youtube-api\Dockerfile") {
    docker-compose build youtube-fetcher 2>$null
    Write-Host "✓ YouTube fetcher built" -ForegroundColor Green
} else {
    Write-Host "⚠ Dockerfile not found - create it first" -ForegroundColor Yellow
}
Write-Host ""

Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║                    SETUP COMPLETE!                        ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green

Write-Host ""
Write-Host "Access Points:" -ForegroundColor Cyan
Write-Host "  NameNode:  http://localhost:9870" -ForegroundColor Yellow
Write-Host "  YARN:      http://localhost:8088" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: Run .\Run-VideoFetcher.ps1" -ForegroundColor Cyan
