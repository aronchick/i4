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

## Use Cases

- Testing edge data validation/cleaning pipelines
- Benchmarking data lake ingestion
- Simulating IoT/OT workloads for Kubernetes/edge deployments
- Testing streaming data processors (Kafka, Pulsar, etc.)
