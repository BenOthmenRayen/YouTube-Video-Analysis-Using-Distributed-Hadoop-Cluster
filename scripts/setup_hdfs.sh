#!/bin/bash
# Initialize HDFS directory structure for YouTube analysis

echo "Creating HDFS directories..."

docker exec -it namenode hdfs dfs -mkdir -p /youtube/videos
docker exec -it namenode hdfs dfs -mkdir -p /youtube/metadata
docker exec -it namenode hdfs dfs -mkdir -p /youtube/thumbnails
docker exec -it namenode hdfs dfs -mkdir -p /youtube/analysis/metadata
docker exec -it namenode hdfs dfs -mkdir -p /youtube/analysis/thumbnails
docker exec -it namenode hdfs dfs -mkdir -p /youtube/analysis/statistics
docker exec -it namenode hdfs dfs -mkdir -p /youtube/results

echo "Setting permissions..."
docker exec -it namenode hdfs dfs -chmod -R 777 /youtube

echo "HDFS setup complete!"
docker exec -it namenode hdfs dfs -ls -R /youtube