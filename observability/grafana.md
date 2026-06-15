# Grafana Dashboards

## Installation (Standalone)

```bash
# Install with APT
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y grafana

sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

## Default Data Sources
- Prometheus (metrics)
- Loki (logs)
- Tempo (traces)
- CloudWatch / Azure Monitor / GCP

## Configuration

```ini
# /etc/grafana/grafana.ini
[server]
domain = grafana.example.com
root_url = https://grafana.example.com

[auth.anonymous]
enabled = true
org_role = Viewer
```
