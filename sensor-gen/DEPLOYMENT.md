# Sensor-Gen Deployment Guide

## Quick Start on Remote Machine

```bash
# 1. Pull the repo
git pull origin main

# 2. Make binary executable (if needed)
chmod +x sensor-gen/sensor-gen-linux-amd64

# 3. Run in background with screen
screen -S sensor-gen
./sensor-gen/sensor-gen-linux-amd64 --rate 1000 -v -o /data/sensors/output.jsonl
# Ctrl+A, D to detach
```

## Platform Binaries

- **Linux (x86_64)**: `sensor-gen-linux-amd64` ← Use this for most cloud VMs
- **Linux (ARM64)**: `sensor-gen-linux-arm64` ← Use for ARM-based servers
- **macOS (Intel)**: `sensor-gen-darwin-amd64`
- **macOS (Apple Silicon)**: `sensor-gen-darwin-arm64`
- **Windows**: `sensor-gen-windows-amd64.exe`

## Usage Examples

```bash
# Generate at 1000/sec indefinitely, verbose output
./sensor-gen-linux-amd64 --rate 1000 -v

# Generate for 1 hour at 10000/sec
./sensor-gen-linux-amd64 --rate 10000 -d 1h -o sensors.jsonl

# Low-rate testing (100/sec) for 30 seconds
./sensor-gen-linux-amd64 --rate 100 -d 30s -v

# Append to existing file
./sensor-gen-linux-amd64 --rate 1000 -d 10s --append

# Background with nohup
nohup ./sensor-gen-linux-amd64 --rate 5000 -v > sensor.log 2>&1 &
```

## Monitoring Running Instance

```bash
# Check if running
ps aux | grep sensor-gen

# Watch output file grow
tail -f output.jsonl

# Watch with formatting
tail -f output.jsonl | jq -c '{sensor: .sensor_id, type: .type, value: .value}'

# Check generation rate
watch 'wc -l output.jsonl'

# Reattach to screen session
screen -r sensor-gen
```

## Stopping

```bash
# If running in screen/tmux: Ctrl+C inside the session

# If running with nohup:
pkill sensor-gen
# Or find PID and kill:
ps aux | grep sensor-gen-linux
kill <PID>
```

## Systemd Service (Optional)

For production deployments, create `/etc/systemd/system/sensor-gen.service`:

```ini
[Unit]
Description=IoT Sensor Data Generator
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/i4/sensor-gen
ExecStart=/home/ubuntu/i4/sensor-gen/sensor-gen-linux-amd64 --rate 10000 -v -o /data/sensors/output.jsonl
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable sensor-gen
sudo systemctl start sensor-gen
sudo systemctl status sensor-gen
```

## Flags Reference

- `-o <file>`: Output file path (default: output.jsonl)
- `--rate <n>`: Entries per second (default: 10000)
- `-d <duration>`: Run duration (0 = indefinite, e.g., 30s, 5m, 1h)
- `-v`: Verbose stats every 5 seconds
- `--append`: Append to existing file instead of overwriting

## Integration with Expanso Edge

The generated JSONL can be consumed by Expanso pipelines:

```bash
# On edge node: Generate data
./sensor-gen-linux-amd64 --rate 1000 -o /data/sensors/input.jsonl &

# Deploy Expanso job to process it
expanso-cli job deploy jobs/sensor-batched-job.yaml
```
