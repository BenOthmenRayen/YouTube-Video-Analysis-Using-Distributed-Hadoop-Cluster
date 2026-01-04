Write-Host "=== Starting YouTube Video Fetcher ===" -ForegroundColor Cyan
Write-Host ""

$container_check = docker ps -a --filter "name=youtube-fetcher" --format "{{.Names}}"
if ($container_check -eq "youtube-fetcher") {
    docker rm -f youtube-fetcher 2>$null
}

Write-Host "Starting video download..." -ForegroundColor Yellow
Write-Host "This will download videos from YouTube and save to HDFS" -ForegroundColor White
Write-Host ""

docker-compose run --rm youtube-fetcher

Write-Host ""
Write-Host "=== Complete ===" -ForegroundColor Green
Write-Host "Check results: .\Check-Results.ps1" -ForegroundColor Cyan
