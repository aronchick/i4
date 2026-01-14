# i4 - IoT/OT Sensor Data Generator

High-throughput sensor data generator simulating pipeline infrastructure (oil & gas, energy). Generates ~10,000+ JSON entries per second for testing edge data processing, data lakes, and streaming pipelines.

## Quick Start

```bash
git clone https://github.com/aronchick/i4.git
cd i4

# Run in Docker (no Go required)
./sensor-gen/run-in-container.sh -d 30s -v

# Or use the binary directly (macOS)
./sensor-gen/sensor-gen -d 30s -v

# Or use the binary directly (Linux)
./sensor-gen/sensor-gen-linux -d 30s -v
```

## Usage

```bash
# Default: output.jsonl at 10k entries/sec, runs until Ctrl+C
./sensor-gen/sensor-gen

# Custom output file
./sensor-gen/sensor-gen -o /path/to/sensors.jsonl

# Run for specific duration
./sensor-gen/sensor-gen -d 60s

# Higher throughput
./sensor-gen/sensor-gen -rate 50000 -d 10s

# Verbose mode (progress every 5s)
./sensor-gen/sensor-gen -v -d 30s
```

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

# macOS
go build -o sensor-gen .

# Linux
GOOS=linux GOARCH=amd64 go build -o sensor-gen-linux .
```

## Expanso Pipelines

This repo includes ready-to-use [Expanso](https://expanso.io) pipelines for edge data processing.

### Sensor Enricher (Streaming)

Adds lineage metadata and validation flags to each record in real-time:

```bash
# Stream from file
cat output.jsonl | expanso-edge run pipelines/sensor-enricher.yaml

# Stream directly from generator (10 seconds)
./sensor-gen/sensor-gen -d 10s | expanso-edge run pipelines/sensor-enricher.yaml
```

Output adds lineage and validation:
```json
{
  "sensor_id": "SNS-flo-2977",
  "value": 12984.71,
  "lineage": {
    "edge_node": "edge-west-01",
    "pipeline": "sensor-enricher",
    "ingested_at": "2024-01-14T05:22:42.000Z"
  },
  "validated": true,
  "is_anomaly": false
}
```

### Sensor Processor (Batched)

Batches records every 10 seconds with anomaly detection and summaries:

```bash
# Process with default batching (1000 records or 10s)
./sensor-gen/sensor-gen -d 60s | expanso-edge run pipelines/sensor-processor.yaml

# Custom batch settings
cat data.jsonl | BATCH_SIZE=500 BATCH_PERIOD=5s expanso-edge run pipelines/sensor-processor.yaml
```

Output includes batch summaries:
```json
{
  "batch_summary": {
    "record_count": 1000,
    "anomaly_count": 23,
    "anomaly_rate": 2,
    "batch_time": "2024-01-14T05:22:52.000Z",
    "edge_node": "edge-west-01"
  },
  "records": [...]
}
```

### Pipeline Features

- **Lineage tracking**: Adds edge node ID, pipeline name, and ingestion timestamp
- **Data validation**: Flags out-of-range values based on sensor type
- **Anomaly detection**: Identifies pressure > 1500 psi, temp out of range, low quality scores
- **Batching**: Configurable batch size and time window for efficient downstream processing

## Deploy to Expanso Cloud

Ready-to-deploy job specs are in the `jobs/` directory.

### Prerequisites

```bash
# Configure Expanso CLI with your profile
expanso-cli profile save prod --endpoint api.expanso.io --token YOUR_TOKEN --select

# Verify connection
expanso-cli node list
```

### Available Jobs

| Job | Description | Input | Output |
|-----|-------------|-------|--------|
| `sensor-enricher-job.yaml` | Streaming enrichment | stdin | stdout |
| `sensor-processor-job.yaml` | Batched with summaries | stdin | stdout (batched) |
| `sensor-to-s3-job.yaml` | Production S3 upload | stdin | S3 (batched) |
| `sensor-file-watcher-job.yaml` | Watch directory for files | file | stdout |

### Deploy a Job

```bash
# Deploy streaming enricher to nodes with role=edge-processor
expanso-cli job deploy jobs/sensor-enricher-job.yaml

# Check status
expanso-cli job describe sensor-enricher
expanso-cli execution list --job sensor-enricher

# View logs
expanso-cli job logs sensor-enricher
```

### Configure for S3 Output

Set these on your edge nodes before deploying `sensor-to-s3-job.yaml`:

```bash
# Required
export S3_BUCKET="my-sensor-data-bucket"

# Optional (have defaults)
export AWS_REGION="us-east-1"
export S3_PREFIX="sensor-data/"
export BATCH_SIZE=1000
export BATCH_PERIOD="60s"
```

### Node Labels

Jobs use selectors to target specific nodes. Label your edge nodes appropriately:

```yaml
# For stdin-based jobs
role: edge-processor

# For S3 output jobs
role: edge-processor
output: s3

# For file watcher jobs
role: edge-processor
input: file
```

## Use Cases

- Testing edge data validation/cleaning pipelines
- Benchmarking data lake ingestion
- Simulating IoT/OT workloads for Kubernetes/edge deployments
- Testing streaming data processors (Kafka, Pulsar, etc.)
