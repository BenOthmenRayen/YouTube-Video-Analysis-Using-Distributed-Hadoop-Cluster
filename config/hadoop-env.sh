# hadoop-env.sh
# JAVA_HOME for Hadoop (Java 8 common path inside these images)
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Hadoop layout used by these images
export HADOOP_HOME=/hadoop
export HADOOP_CONF_DIR=/hadoop/etc/hadoop

# Heap size for daemons (adjust if you have more RAM)
export HADOOP_HEAPSIZE=1024

# Prefer IPv4 to avoid IPv6 networking surprises inside Docker
export HADOOP_OPTS="$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"
