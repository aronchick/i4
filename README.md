# i4 - IoT/OT Sensor Data Generator

High-throughput sensor data generator simulating pipeline infrastructure (oil & gas, energy). Generates ~10,000+ JSON entries per second for testing edge data processing, data lakes, and streaming pipelines.

**[View Interactive Walkthrough](docs/index.html)** - A visual guide to the complete workflow.

## Quick Start

```bash
git clone https://github.com/aronchick/i4.git
cd i4

# Run in Docker (no Go required)
./sensor-gen/run-in-container.sh -d 30s -v

# Or use the binary directly (macOS Apple Silicon)
./sensor-gen/sensor-gen-darwin-arm64 -d 30s -v

# Or use the binary directly (macOS Intel)
./sensor-gen/sensor-gen-darwin-amd64 -d 30s -v

# Or use the binary directly (Linux x86_64)
./sensor-gen/sensor-gen-linux-amd64 -d 30s -v
```

## Usage

```bash
# Default: output.jsonl at 10k entries/sec, runs until Ctrl+C
./sensor-gen/sensor-gen-linux-amd64

# Custom output file
./sensor-gen/sensor-gen-linux-amd64 -o /path/to/sensors.jsonl

# Run for specific duration
./sensor-gen/sensor-gen-linux-amd64 -d 60s

# Higher throughput
./sensor-gen/sensor-gen-linux-amd64 -rate 50000 -d 10s

# Verbose mode (progress every 5s)
./sensor-gen/sensor-gen-linux-amd64 -v -d 30s

# Append to existing file
./sensor-gen/sensor-gen-linux-amd64 -d 30s --append
```

### Command Line Flags

| Flag | Default | Description |
|------|---------|-------------|
| `-o <file>` | `output.jsonl` | Output file path |
| `-rate <n>` | `10000` | Target entries per second |
| `-d <duration>` | `0` (indefinite) | Run duration (e.g., `30s`, `5m`, `1h`) |
| `-v` | `false` | Verbose output with stats every 5s |
| `--append` | `false` | Append to existing file instead of overwriting |

### Platform Binaries

| Platform | Binary |
|----------|--------|
| Linux (x86_64) | `sensor-gen-linux-amd64` |
| Linux (ARM64) | `sensor-gen-linux-arm64` |
| macOS (Apple Silicon) | `sensor-gen-darwin-arm64` |
| macOS (Intel) | `sensor-gen-darwin-amd64` |
| Windows | `sensor-gen-windows-amd64.exe` |

### Docker Usage

```bash
# Run in container (output to current directory)
./sensor-gen/run-in-container.sh -d 60s -v

# Custom output directory
OUTPUT_DIR=/tmp/sensor-data ./sensor-gen/run-in-container.sh -d 10s
```

## Sample Output

```json
{
  "sensor_id": "SNS-flo-2977",
  "timestamp": "2024-01-14T05:22:42.436377Z",
  "type": "flow_rate",
  "value": 12984.71,
  "unit": "bbl/hr",
  "location": {
    "lat": 37.82,
    "lon": -104.56,
    "mile_post": 203.7
  },
  "pipeline_id": "PIPE-LA-001",
  "status": "normal",
  "quality_score": 0.87,
  "alert_level": "low"
}
```

## Sensor Types

| Type | Unit | Range | Description |
|------|------|-------|-------------|
| pressure | psi | 200-1500 | Pipeline pressure |
| temperature | fahrenheit | -20 to 180 | Ambient/fluid temp |
| flow_rate | bbl/hr | 0-50000 | Fluid flow rate |
| vibration | mm/s | 0-25 | Equipment vibration |
| corrosion | mpy | 0-50 | Corrosion rate |
| humidity | percent | 0-100 | Environmental humidity |
| gas_detector | ppm | 0-1000 | Gas leak detection |
| valve_position | percent | 0-100 | Valve open percentage |

## Features

- **High throughput**: 10k+ entries/sec with buffered I/O
- **Realistic data**: 8 sensor types with appropriate ranges
- **Anomaly injection**: 2% of readings exceed normal ranges
- **Pipeline simulation**: 8 pipeline IDs across US oil/gas regions
- **Quality scores**: Each reading includes a quality metric
- **Alert levels**: Automatic alerting on anomalous values

## Building from Source

```bash
cd sensor-gen

# Build for current platform
go build -o sensor-gen .

# Cross-compile for Linux (x86_64)
GOOS=linux GOARCH=amd64 go build -o sensor-gen-linux-amd64 .

# Cross-compile for Linux (ARM64)
GOOS=linux GOARCH=arm64 go build -o sensor-gen-linux-arm64 .

# Cross-compile for macOS (Apple Silicon)
GOOS=darwin GOARCH=arm64 go build -o sensor-gen-darwin-arm64 .

# Cross-compile for macOS (Intel)
GOOS=darwin GOARCH=amd64 go build -o sensor-gen-darwin-amd64 .
```

## Expanso Edge Integration

[Expanso](https://expanso.io) pipelines for edge data processing. Use sensor-gen to generate data on edge nodes, then process with Expanso Edge pipelines deployed via the control plane.

### Workflow Overview

1. **Generate sensor data** on edge nodes using sensor-gen
2. **Deploy pipeline jobs** via `expanso-cli` to process the data
3. **Monitor executions** via the Expanso control plane

### Step 1: Generate Data on Edge Node

```bash
# On your edge node, run sensor-gen to generate data
./sensor-gen/sensor-gen-linux-amd64 --rate 1000 -v -o /data/sensors/input.jsonl

# Or run in a container
OUTPUT_DIR=/data/sensors ./sensor-gen/run-in-container.sh -d 60s -v -o input.jsonl
```

### Step 2: Bootstrap Edge Node

```bash
# Install expanso-edge (one-time)
curl -fsSL https://get.expanso.io/edge/install.sh | bash

# Bootstrap to your Expanso Cloud organization
expanso-edge bootstrap --token YOUR_BOOTSTRAP_TOKEN

# Start the edge agent
expanso-edge run
```

### Step 3: Deploy Pipeline Jobs

```bash
# Deploy from your workstation using expanso-cli
expanso-cli job deploy jobs/sensor-batched-enriched-job.yaml

# Check status
expanso-cli job describe sensor-batched-enriched
expanso-cli execution list --job sensor-batched-enriched
```

### Pipeline Pattern

Pipelines use `batched` input wrapper to accumulate records before output:

```yaml
input:
  batched:
    child:
      file:
        paths:
          - "${INPUT_FILE:output.jsonl}"
        scanner:
          lines: {}
    policy:
      count: 1000               # Records per batch
      period: 10s               # Or flush after 10s
      processors:
        - archive:
            format: json_array  # [{},{},...] per batch

output:
  file:
    path: './output/batch_${! timestamp_unix_nano() }.json'
    codec: all-bytes
```

### Output Format (Enriched)

```json
{
  "batch_meta": {
    "record_count": 1000,
    "anomaly_count": 23,
    "anomaly_rate_pct": 2,
    "batch_time": "2024-01-14T05:22:52.000Z",
    "edge_node": "edge-west-01",
    "pipeline": "sensor-batched-enriched"
  },
  "records": [
    {
      "sensor_id": "SNS-flo-2977",
      "value": 12984.71,
      "lineage": {
        "edge_node": "edge-west-01",
        "pipeline": "sensor-batched-enriched",
        "ingested_at": "2024-01-14T05:22:42.000Z"
      },
      "data_quality": {
        "is_anomaly": false,
        "anomaly_reasons": [],
        "validated": true
      }
    }
  ]
}
```

## Run Pipelines Locally

Test pipelines locally before deploying to Expanso Cloud using `expanso-edge run`.

### Prerequisites

```bash
# Install expanso-edge (includes local pipeline runner)
curl -fsSL https://get.expanso.io/edge/install.sh | bash
```

### Basic Batching Pipeline

```bash
# 1. Generate test data
./sensor-gen/sensor-gen-linux-amd64 -d 30s -v -o /tmp/sensors.jsonl

# 2. Run the basic batching pipeline
INPUT_FILE=/tmp/sensors.jsonl OUTPUT_DIR=/tmp/batched \
  expanso-edge run pipelines/sensor-batched.yaml

# 3. Check the output
ls -la /tmp/batched/
cat /tmp/batched/batch_*.json | head -20
```

### Enriched Pipeline with Lineage

```bash
# Run the enriched pipeline (adds lineage + anomaly detection)
INPUT_FILE=/tmp/sensors.jsonl OUTPUT_DIR=/tmp/enriched \
  expanso-edge run pipelines/sensor-batched-enriched.yaml

# View batch metadata
cat /tmp/enriched/batch_*.json | jq '.batch_meta'
```

### Pipeline Configuration

Pipelines accept environment variables for configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `INPUT_FILE` | `output.jsonl` | Path to input JSONL file |
| `OUTPUT_DIR` | `./output` | Directory for batch output files |
| `BATCH_SIZE` | `1000` | Records per batch |
| `BATCH_PERIOD` | `10s` | Max time before flushing batch |
| `EDGE_NODE_ID` | hostname | Node identifier for lineage |

## Deploy to Expanso Cloud

Job specs in `jobs/` are ready for `expanso-cli job deploy`.

### Prerequisites

```bash
expanso-cli profile save prod --endpoint api.expanso.io --token YOUR_TOKEN --select
expanso-cli node list
```

### Available Jobs

| Job | Description | Output |
|-----|-------------|--------|
| `sensor-batched-job.yaml` | Basic batched generation | Local files |
| `sensor-batched-enriched-job.yaml` | With lineage + validation | Local files |
| `sensor-batched-to-s3-job.yaml` | Production S3 upload | S3 (partitioned) |

### Deploy

```bash
# Deploy to nodes with role=edge-processor
expanso-cli job deploy jobs/sensor-batched-enriched-job.yaml

# Check status
expanso-cli job describe sensor-batched-enriched
expanso-cli execution list --job sensor-batched-enriched
```

### S3 Configuration

For `sensor-batched-to-s3-job.yaml`, set on edge nodes:

```bash
export S3_BUCKET="my-sensor-bucket"     # Required
export AWS_REGION="us-east-1"           # Optional
export S3_PREFIX="sensor-data/"         # Optional
export BATCH_PERIOD="60s"               # Optional (default 60s for S3)
```

S3 path pattern: `sensor-data/2024/01/14/edge-hostname_1705234567890123456.json`

### Node Labels

```yaml
# For file output jobs
role: edge-processor

# For S3 output jobs
role: edge-processor
output: s3
```

## Use Cases

- Testing edge data validation/cleaning pipelines
- Benchmarking data lake ingestion
- Simulating IoT/OT workloads for Kubernetes/edge deployments
- Testing streaming data processors (Kafka, Pulsar, etc.)
