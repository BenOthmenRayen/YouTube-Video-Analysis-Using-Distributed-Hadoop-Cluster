#!/bin/bash
# Run MapReduce job for video metadata extraction

HADOOP_STREAMING_JAR="/hadoop/share/hadoop/tools/lib/hadoop-streaming-*.jar"

hadoop jar $HADOOP_STREAMING_JAR \
    -input /youtube/videos \
    -output /youtube/analysis/metadata \
    -mapper mapper.py \
    -reducer reducer.py \
    -file mapper.py \
    -file reducer.py