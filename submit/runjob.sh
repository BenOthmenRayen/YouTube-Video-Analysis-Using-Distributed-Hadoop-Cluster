#!/bin/sh
#
# submit/runjob.sh
# Placeholder runner: it does nothing by default.
# Put your job files into /app and run them manually
# (or modify this script later to auto-run your job).
#

echo "runjob.sh: placeholder script running inside submit container."
echo "List files in /app:"
ls -la /app

# Sleep indefinitely so the container keeps running after build/start.
# If you want this script to automatically launch something, edit it later.
while true; do sleep 3600; done
