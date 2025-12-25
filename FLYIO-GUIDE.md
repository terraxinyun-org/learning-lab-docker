# Fly.io Management Guide

## Installation

```bash
curl -L https://fly.io/install.sh | sh
```

The CLI installs to `~/.fly/bin/fly`. Add to PATH or use full path.

## Authentication

```bash
# Login (opens browser for auth)
fly auth login

# Verify login
fly auth whoami

# List organizations
fly orgs list
```

## App Management

### Create App
```bash
fly apps create my-app-name --org personal
```

### List Apps
```bash
fly apps list
```

### Destroy App
```bash
fly apps destroy my-app-name --yes
```

### Check App Status
```bash
fly status --app my-app-name
```

## Machine Management

### Run a Machine (Quick Start)
```bash
# Basic - just run an image
fly machine run nginx --app my-app --region sin

# With ports exposed
fly machine run nginx --app my-app --region sin \
  --port 80:80/tcp:http \
  --port 443:80/tcp:http:tls

# With environment variables
fly machine run myimage --app my-app \
  --env PASSWORD=secret \
  --vm-memory 512
```

### List Machines
```bash
fly machine list --app my-app
```

### Destroy Machine
```bash
fly machine destroy MACHINE_ID --app my-app --force
```

### Update Machine (e.g., add ports)
```bash
fly machine update MACHINE_ID --app my-app \
  --port 80:80/tcp:http \
  --port 443:80/tcp:http:tls \
  --yes
```

## Deploying with Dockerfile

### Project Structure
```
my-project/
├── Dockerfile
├── fly.toml
└── ... (app files)
```

### fly.toml Example
```toml
app = "my-app-name"
primary_region = "sin"

[build]

[env]
  PASSWORD = "changeme"

[http_service]
  internal_port = 8080
  force_https = true

[[vm]]
  memory = "512mb"
  cpu_kind = "shared"
  cpus = 1
```

### Deploy
```bash
fly deploy
```

## Networking

### Allocate Public IP
```bash
# Shared IPv4 (free)
fly ips allocate-v4 --shared --app my-app

# List IPs
fly ips list --app my-app
```

### Access App
- Apps get automatic domain: `https://APP-NAME.fly.dev`
- SSL/TLS is automatic

## Troubleshooting

### View Logs
```bash
fly logs --app my-app
```

### SSH into Machine
```bash
# Issue SSH certificate first
fly ssh issue personal --agent

# Then connect
fly ssh console --app my-app
```

**Note:** SSH may fail with "unable to authenticate" - this is a known issue with some configurations.

### Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `unknown flag: --app` | Wrong command syntax | Check docs, some commands use positional args |
| `yes flag must be specified` | Interactive prompts disabled | Add `--yes` flag |
| SSH authentication failed | No SSH cert issued | Use `fly ssh issue` first |
| App not listening on expected address | Container not binding to 0.0.0.0 | Configure app to listen on `0.0.0.0:PORT` |
| File permission errors in VS Code | Files created as root | Use `COPY --chown=user:user` in Dockerfile |

### Check VM Sizes
```bash
fly platform vm-sizes
```

Output:
```
shared-cpu-1x    1 core    256 MB   (cheapest)
shared-cpu-2x    2 cores   512 MB
shared-cpu-4x    4 cores   1 GB
performance-1x   1 core    2 GB     (dedicated)
...
```

### Check Regions
```bash
fly regions list
```

Common regions:
- `sin` - Singapore
- `hkg` - Hong Kong
- `nrt` - Tokyo
- `syd` - Sydney
- `iad` - Virginia, USA
- `lhr` - London

## Free Tier Limits

- 3 shared-cpu-1x VMs (256MB each)
- 3GB persistent storage
- 160GB outbound bandwidth
- No credit card required to start

## Code-Server (VS Code in Browser) Setup

### Dockerfile
```dockerfile
FROM codercom/code-server:latest

USER root

# Install tools
RUN apt-get update && apt-get install -y \
    sudo curl git nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Give user sudo access
RUN echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER coder

# Create workspace
RUN mkdir -p /home/coder/project
COPY --chown=coder:coder ./files /home/coder/project/

WORKDIR /home/coder/project
```

### fly.toml for code-server
```toml
app = "my-lab"
primary_region = "sin"

[build]

[env]
  PASSWORD = "studentpassword"

[http_service]
  internal_port = 8080
  force_https = true

[[vm]]
  memory = "512mb"
  cpu_kind = "shared"
  cpus = 1
```

### Key Points
- code-server runs on port 8080 by default
- Set PASSWORD env var for login
- Use `--chown=coder:coder` in COPY to fix permission issues
- Need at least 512MB RAM for comfortable usage

## Useful Commands Reference

```bash
# Auth
fly auth login
fly auth whoami

# Apps
fly apps create NAME
fly apps list
fly apps destroy NAME --yes
fly status --app NAME

# Machines
fly machine run IMAGE --app NAME --region REGION
fly machine list --app NAME
fly machine destroy ID --app NAME --force

# Deploy
fly deploy

# Network
fly ips allocate-v4 --shared --app NAME
fly ips list --app NAME

# Debug
fly logs --app NAME
fly ssh console --app NAME

# Info
fly platform vm-sizes
fly regions list
```
