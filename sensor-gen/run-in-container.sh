#!/bin/bash
# Run sensor-gen in a Linux container
# Usage: ./run-in-container.sh [args...]
# Examples:
#   ./run-in-container.sh                    # Default: 10k/sec to output.jsonl
#   ./run-in-container.sh -d 30s -v          # 30 seconds, verbose
#   ./run-in-container.sh -rate 50000 -d 10s # 50k/sec for 10 seconds

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)}"

# Default args if none provided
ARGS="${@:--d 10s -v}"

echo "Running sensor-gen in container..."
echo "Output directory: $OUTPUT_DIR"
echo "Args: $ARGS"
echo ""

# Use -it only if we have a TTY
TTY_FLAG=""
if [ -t 0 ]; then
    TTY_FLAG="-it"
fi

docker run --rm $TTY_FLAG \
    -v "$SCRIPT_DIR/sensor-gen-linux:/sensor-gen:ro" \
    -v "$OUTPUT_DIR:/data" \
    -w /data \
    alpine:latest \
    /sensor-gen $ARGS
