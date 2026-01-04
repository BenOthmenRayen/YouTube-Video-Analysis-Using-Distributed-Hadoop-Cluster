# submit/Dockerfile
# Small submit helper based on your existing Hadoop base image.
FROM bde2020/hadoop-base:2.0.0-hadoop3.2.1-java8

# Working directory where you'll copy job artifacts later
WORKDIR /app

# Copy run script (if present at build time)
COPY runjob.sh /app/runjob.sh
RUN chmod +x /app/runjob.sh || true

# Add a small entrypoint that lists /app and then keeps the container alive.
# You can run anything later inside the container with "docker exec".
CMD ["sh", "-c", "echo 'Submit container started. /app contains:' && ls -la /app && /app/runjob.sh || tail -f /dev/null"]
