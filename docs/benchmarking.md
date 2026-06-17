# Benchmarking Guide

The benchmark scripts use ApacheBench (`ab`) and were adapted from the benchmarking lab.

## Install ApacheBench

Amazon Linux 2023:

```bash
sudo dnf install -y httpd-tools
```

Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y apache2-utils
```

macOS:

```bash
brew install httpd
```

Check installation:

```bash
ab -V
```

## Run sample scenarios

From the repository root:

```bash
TARGET_URL="http://PASTE_ALB_DNS_NAME_HERE/" bash scripts/run-sample-scenarios.sh
```

## Run one custom scenario

```bash
TARGET_URL="http://PASTE_ALB_DNS_NAME_HERE/" \
SCENARIO_NAME="throughput-baseline" \
TARGET_LABEL="alb" \
REQUESTS=100 \
CONCURRENCY=10 \
RESET_SUMMARY=true \
bash scripts/run-http-benchmark.sh
```

## Analyze results

```bash
bash scripts/analyze-summary.sh
```

Generated files:

```text
results/summary.csv
results/analysis.md
results/*.ab.txt
```

## Metrics to discuss

- Requests per second: throughput
- Average time: general latency
- p95 time: tail latency
- Failed requests: reliability signal
- Concurrency: number of parallel requests attempted
