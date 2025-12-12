# Install Prometheus & Grafana (manual workflow)

This document describes the `install-monitoring` GitHub Actions workflow that installs Prometheus and Grafana Docker images on an EC2 instance.

## What the workflow does

- Is triggered manually via the GitHub Actions UI (workflow_dispatch).
- SSHes into the target EC2 instance and:
  - Installs Docker if missing (supports Ubuntu/Debian and Amazon Linux-like setups).
  - Pulls `prom/prometheus:latest` and `grafana/grafana:latest` images.
  - Starts Prometheus (port 9090) and Grafana (port 3000) as Docker containers.

## How to run

1. Go to the repository on GitHub → Actions → "Install Prometheus & Grafana (Manual)" workflow.
2. Click "Run workflow" and click the green button.

## Required GitHub Secrets

Add the following repository secrets (Settings → Secrets → Actions):

- `EC2_HOST` — the public IP or DNS name of the EC2 instance
- `EC2_USER` — username to log in (e.g., `ec2-user`, `ubuntu`)
- `EC2_SSH_KEY` — the **private SSH key** (PEM/OPENSSH) contents for the user above

Note: The SSH key should give you access to the instance and the user should be able to run `sudo` to install/start Docker.

## Notes & next steps

- The workflow uses default images and no extra configuration for Prometheus; to use a custom Prometheus config, you should copy a `prometheus.yml` to the instance and run Prometheus with `-v` mapping.
- Grafana data is backed by a Docker volume named `grafana-storage` so dashboards persist across container restarts.
- Ports exposed: Prometheus 9090, Grafana 3000. Open them in your security group if you want to access them from the Internet (recommended: use secure access / VPN and not open to the public).

---

If you want I can:
- Add an optional input to the workflow to provide image tags.
- Expand the script to push a default `prometheus.yml` and a `docker-compose.yml` to the server for better manageability.
