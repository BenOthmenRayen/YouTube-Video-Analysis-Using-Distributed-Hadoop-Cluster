#!/bin/bash
# Test Hadoop cluster health

echo "=== Checking NameNode ==="
curl -s http://localhost:9870/jmx | grep -q "NameNode" && echo "✅ NameNode OK" || echo "❌ NameNode FAIL"

echo ""
echo "=== Checking YARN ResourceManager ==="
curl -s http://localhost:8088/cluster/cluster | grep -q "cluster" && echo "✅ YARN OK" || echo "❌ YARN FAIL"

echo ""
echo "=== HDFS Report ==="
docker exec namenode hdfs dfsadmin -report

echo ""
echo "=== YARN Nodes ==="
docker exec resourcemanager yarn node -list

echo ""
echo "=== DataNode Status ==="
docker-compose ps | grep datanode