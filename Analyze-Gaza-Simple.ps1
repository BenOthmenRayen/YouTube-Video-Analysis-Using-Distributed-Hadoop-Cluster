# Gaza Videos Analysis - Simple Version
# No special characters, pure PowerShell

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "          GAZA VIDEOS ANALYSIS" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Load all metadata from HDFS
Write-Host "Loading metadata from HDFS..." -ForegroundColor Yellow
$files = docker exec namenode hdfs dfs -ls /youtube/metadata 2>$null | Select-String ".json"

if ($files.Count -eq 0) {
    Write-Host "No metadata files found!" -ForegroundColor Red
    Write-Host "Run .\Run-VideoFetcher.ps1 first!" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found $($files.Count) metadata files" -ForegroundColor Green
Write-Host ""

# Parse all videos
$videos = @()
foreach ($file in $files) {
    $filepath = $file.ToString().Split()[-1]
    $json_data = docker exec namenode hdfs dfs -cat $filepath 2>$null
    
    try {
        $video = $json_data | ConvertFrom-Json
        $videos += $video
    } catch {
        # Skip invalid JSON
    }
}

Write-Host "Loaded $($videos.Count) videos successfully" -ForegroundColor Green
Write-Host ""

# ============================================
# OVERALL SUMMARY
# ============================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "OVERALL SUMMARY" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

$totalVideos = $videos.Count
$totalViews = ($videos | Measure-Object -Property views -Sum).Sum
$totalLikes = ($videos | Measure-Object -Property likes -Sum).Sum
$avgViews = if ($totalVideos -gt 0) { [math]::Round($totalViews / $totalVideos) } else { 0 }
$avgLikes = if ($totalVideos -gt 0) { [math]::Round($totalLikes / $totalVideos) } else { 0 }

Write-Host "Total Videos Analyzed: " -NoNewline -ForegroundColor White
Write-Host $totalVideos -ForegroundColor Green
Write-Host "Total Views:          " -NoNewline -ForegroundColor White
Write-Host ("{0:N0}" -f $totalViews) -ForegroundColor Green
Write-Host "Total Likes:          " -NoNewline -ForegroundColor White
Write-Host ("{0:N0}" -f $totalLikes) -ForegroundColor Green
Write-Host "Average Views/Video:  " -NoNewline -ForegroundColor White
Write-Host ("{0:N0}" -f $avgViews) -ForegroundColor Green
Write-Host "Average Likes/Video:  " -NoNewline -ForegroundColor White
Write-Host ("{0:N0}" -f $avgLikes) -ForegroundColor Green
Write-Host ""

# ============================================
# VIEW STATISTICS
# ============================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "VIEW STATISTICS" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

$viewStats = $videos | Measure-Object -Property views -Minimum -Maximum -Average
Write-Host "Highest Views:    " -NoNewline -ForegroundColor White
Write-Host ("{0:N0}" -f $viewStats.Maximum) -ForegroundColor Green
Write-Host "Lowest Views:     " -NoNewline -ForegroundColor White
Write-Host ("{0:N0}" -f $viewStats.Minimum) -ForegroundColor Green
Write-Host "Average Views:    " -NoNewline -ForegroundColor White
Write-Host ("{0:N0}" -f $viewStats.Average) -ForegroundColor Green
Write-Host ""

Write-Host "TOP 10 MOST VIEWED VIDEOS:" -ForegroundColor Yellow
$topViewed = $videos | Sort-Object -Property views -Descending | Select-Object -First 10
$rank = 1
foreach ($video in $topViewed) {
    $titleText = if ($video.title.Length -gt 70) { $video.title.Substring(0, 70) } else { $video.title }
    Write-Host "$rank. $titleText" -ForegroundColor White
    Write-Host "   Views: " -NoNewline -ForegroundColor Gray
    Write-Host ("{0:N0}" -f $video.views) -NoNewline -ForegroundColor Green
    Write-Host " | Channel: " -NoNewline -ForegroundColor Gray
    Write-Host $video.author -ForegroundColor Yellow
    $rank++
}
Write-Host ""

# ============================================
# ENGAGEMENT ANALYSIS
# ============================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "ENGAGEMENT ANALYSIS" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

$likeStats = $videos | Measure-Object -Property likes -Sum -Average
Write-Host "Total Likes:      " -NoNewline -ForegroundColor White
Write-Host ("{0:N0}" -f $likeStats.Sum) -ForegroundColor Green
Write-Host "Average Likes:    " -NoNewline -ForegroundColor White
Write-Host ("{0:N0}" -f $likeStats.Average) -ForegroundColor Green
Write-Host ""

# Calculate engagement rate
$engagement = @()
foreach ($video in $videos) {
    if ($video.views -gt 0) {
        $rate = ($video.likes / $video.views) * 100
        $engagement += [PSCustomObject]@{
            Title = $video.title
            Rate = $rate
            Views = $video.views
            Likes = $video.likes
        }
    }
}

Write-Host "TOP 5 HIGHEST ENGAGEMENT RATE:" -ForegroundColor Yellow
$topEngagement = $engagement | Sort-Object -Property Rate -Descending | Select-Object -First 5
$rank = 1
foreach ($item in $topEngagement) {
    $titleText = if ($item.Title.Length -gt 70) { $item.Title.Substring(0, 70) } else { $item.Title }
    Write-Host "$rank. $titleText" -ForegroundColor White
    Write-Host "   Engagement: " -NoNewline -ForegroundColor Gray
    Write-Host ("{0:F2}%" -f $item.Rate) -NoNewline -ForegroundColor Green
    Write-Host " | Views: " -NoNewline -ForegroundColor Gray
    Write-Host ("{0:N0}" -f $item.Views) -ForegroundColor Yellow
    $rank++
}
Write-Host ""

# ============================================
# CHANNEL ANALYSIS
# ============================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "CHANNEL ANALYSIS" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

$channels = $videos | Group-Object -Property author | Sort-Object -Property Count -Descending
Write-Host "Total Unique Channels: " -NoNewline -ForegroundColor White
Write-Host $channels.Count -ForegroundColor Green
Write-Host ""

Write-Host "TOP 10 CHANNELS BY VIDEO COUNT:" -ForegroundColor Yellow
$topChannels = $channels | Select-Object -First 10
foreach ($channel in $topChannels) {
    Write-Host "  $($channel.Count) videos - " -NoNewline -ForegroundColor Cyan
    Write-Host $channel.Name -ForegroundColor White
}
Write-Host ""

# ============================================
# TAG ANALYSIS
# ============================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "TAG/KEYWORD ANALYSIS" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

$allTags = @()
foreach ($video in $videos) {
    if ($video.tags) {
        foreach ($tag in $video.tags) {
            $allTags += $tag.ToLower()
        }
    }
}

if ($allTags.Count -gt 0) {
    $tagGroups = $allTags | Group-Object | Sort-Object -Property Count -Descending

    Write-Host "Total Tags Found: " -NoNewline -ForegroundColor White
    Write-Host $allTags.Count -ForegroundColor Green
    Write-Host "Unique Tags: " -NoNewline -ForegroundColor White
    Write-Host $tagGroups.Count -ForegroundColor Green
    Write-Host ""

    Write-Host "TOP 20 MOST COMMON TAGS:" -ForegroundColor Yellow
    $topTags = $tagGroups | Select-Object -First 20
    foreach ($tag in $topTags) {
        Write-Host "  $($tag.Count.ToString().PadLeft(3)) - " -NoNewline -ForegroundColor Cyan
        Write-Host $tag.Name -ForegroundColor White
    }
} else {
    Write-Host "No tags found in videos" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# TITLE KEYWORD ANALYSIS
# ============================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "TITLE KEYWORD ANALYSIS" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

$stopwords = @('the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'but', 'is', 'are', 'was', 'were', 'from', 'with', 'about', 'this', 'that')

$allWords = @()
foreach ($video in $videos) {
    $words = $video.title.ToLower() -split '\W+' | Where-Object { 
        $_.Length -ge 4 -and $_ -notin $stopwords 
    }
    $allWords += $words
}

$wordGroups = $allWords | Group-Object | Sort-Object -Property Count -Descending

Write-Host "TOP 15 KEYWORDS IN TITLES:" -ForegroundColor Yellow
$topWords = $wordGroups | Select-Object -First 15
foreach ($word in $topWords) {
    Write-Host "  $($word.Count.ToString().PadLeft(3)) - " -NoNewline -ForegroundColor Cyan
    Write-Host $word.Name -ForegroundColor White
}
Write-Host ""

# ============================================
# PUBLICATION TIMELINE
# ============================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "PUBLICATION TIMELINE" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

$dates = @()
foreach ($video in $videos) {
    if ($video.publish_date) {
        try {
            $date = [DateTime]::Parse($video.publish_date)
            $dates += $date
        } catch {
            # Skip invalid dates
        }
    }
}

if ($dates.Count -gt 0) {
    $dates = $dates | Sort-Object
    Write-Host "Oldest Video: " -NoNewline -ForegroundColor White
    Write-Host $dates[0].ToString("yyyy-MM-dd") -ForegroundColor Green
    Write-Host "Newest Video: " -NoNewline -ForegroundColor White
    Write-Host $dates[-1].ToString("yyyy-MM-dd") -ForegroundColor Green
    Write-Host ""
    
    $years = $dates | Group-Object -Property Year | Sort-Object -Property Name
    Write-Host "VIDEOS BY YEAR:" -ForegroundColor Yellow
    foreach ($year in $years) {
        Write-Host "  $($year.Name): " -NoNewline -ForegroundColor Cyan
        Write-Host "$($year.Count) videos" -ForegroundColor White
    }
}
Write-Host ""

# ============================================
# FINAL SUMMARY
# ============================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "ANALYSIS COMPLETE" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Results saved to HDFS: /youtube/metadata" -ForegroundColor Green
Write-Host "View in NameNode UI: http://localhost:9870" -ForegroundColor Yellow
Write-Host ""