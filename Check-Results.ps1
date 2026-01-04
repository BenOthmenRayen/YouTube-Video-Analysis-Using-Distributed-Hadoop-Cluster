Write-Host "=== YouTube Analysis Results ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1] HDFS Structure:" -ForegroundColor Yellow
docker exec namenode hdfs dfs -ls -R /youtube 2>$null
Write-Host ""

Write-Host "[2] Downloaded Videos:" -ForegroundColor Yellow
$video_count = docker exec namenode hdfs dfs -ls /youtube/videos 2>$null | Select-String ".mp4" | Measure-Object
Write-Host "  Total: $($video_count.Count)" -ForegroundColor White
if ($video_count.Count -gt 0) {
    docker exec namenode hdfs dfs -ls /youtube/videos 2>$null | Select-String ".mp4"
}
Write-Host ""

Write-Host "[3] Metadata Files:" -ForegroundColor Yellow
$meta_count = docker exec namenode hdfs dfs -ls /youtube/metadata 2>$null | Select-String ".json" | Measure-Object
Write-Host "  Total: $($meta_count.Count)" -ForegroundColor White
if ($meta_count.Count -gt 0) {
    docker exec namenode hdfs dfs -ls /youtube/metadata 2>$null | Select-String ".json"
}
Write-Host ""

Write-Host "[4] Storage Used:" -ForegroundColor Yellow
docker exec namenode hdfs dfs -du -h /youtube 2>$null
Write-Host ""

Write-Host "[5] Cluster Status:" -ForegroundColor Yellow
docker exec resourcemanager yarn node -list 2>$null
Write-Host ""

Write-Host "=== Complete ===" -ForegroundColor Green
Write-Host "NameNode: http://localhost:9870" -ForegroundColor Yellow
