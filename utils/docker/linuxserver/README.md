# linuxserver/openvscode-server — Local Testing & AWS ECR Deployment

Base image: [`lscr.io/linuxserver/openvscode-server`](https://hub.docker.com/r/linuxserver/openvscode-server)  
ECR repository: `ai-arena-mdb-openvscode-linuxserver`

## What's included

| Tool | Version (ARG default) |
|---|---|
| OpenVSCode Server | 1.109.5 |
| Node.js | 24 |
| npm | 11.8.0 |
| Python | 3.12 |
| Java (headless) | 21 |
| MongoDB MCP Server | 1.9.0 |
| mongosh | 2.8.2 |
| uv | latest |
| AWS CLI | v2 latest |

**VS Code extensions baked into the image:**
- `mongodb.mongodb-vscode`
- `humao.rest-client`
- `saoudrizwan.claude-dev`

---

## Prerequisites

- **Docker Desktop** installed and running
- **AWS CLI** configured with profile `Solution-Architects.User-979559056307`

---

## Local Testing

### Free up space before building

Large images can fail during the buildx export/import phase (`io: read/write on closed pipe`).
Run this before building to free disk space:

```bash
docker system prune -a
docker builder prune
```

### Build the image

```bash
# Native architecture (fast, for local inspection)
docker build -t mdb-openvscode-linuxserver:test -f mdb-openvscode-linuxserver.dockerfile .

# AMD64 cross-platform build (matches production, required on Apple Silicon)
docker buildx build --platform linux/amd64 \
  -t mdb-openvscode-linuxserver:test \
  -f mdb-openvscode-linuxserver.dockerfile . --load
```

### Run the container

```bash
# --platform linux/amd64 is required on Apple Silicon to match the build platform
docker run -d -p 3000:3000 \
  --platform linux/amd64 \
  -e PUID=1000 -e PGID=1000 -e TZ=Etc/UTC \
  --name openvscode-linuxserver-test \
  mdb-openvscode-linuxserver:test
```

Open your browser at `http://localhost:3000`.

> `PUID` and `PGID` control the UID/GID of the runtime user inside the container (`abc`).  
> Set them to match your host user to avoid volume permission issues.

### Stop and clean up

```bash
docker stop openvscode-linuxserver-test
docker rm -f openvscode-linuxserver-test
docker rmi mdb-openvscode-linuxserver:test

# Remove all unused Docker resources (optional)
docker system prune -a
```

---

## Deploy to AWS ECR

```bash
./deploy-linuxserver.sh
```

The script will:
1. Verify Docker Desktop is running
2. Authenticate with AWS ECR
3. Create the ECR repository if it does not exist (tagged `noreap=true`)
4. Build the image for `linux/amd64`
5. Push with two tags: `latest` and `YYYYMMDD`
6. Print the full image paths for use in Helm

### Helm values

```yaml
image:
  repository: <ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com/ai-arena-mdb-openvscode-linuxserver
  tag: latest
  pullPolicy: Always

podSecurityContext:
  runAsUser: 0   # s6-overlay needs root at startup; drops to PUID at runtime
  fsGroup: 1000

env:
  - name: PUID
    value: "1000"
  - name: PGID
    value: "1000"
  - name: TZ
    value: "Etc/UTC"
```

---

## Key differences from the gitpod image

| | `gitpod/openvscode-server` | `linuxserver/openvscode-server` |
|---|---|---|
| Base OS | Debian | Ubuntu Noble (24.04) |
| Runtime user | `openvscode-server` (UID 1000) | `abc` (UID set via `PUID`) |
| Init system | None | s6-overlay |
| VS Code binary | `/home/.openvscode-server/bin/openvscode-server` | `/app/openvscode-server/bin/openvscode-server` |
| Extensions dir | `~/.openvscode-server/extensions` | `/config/extensions` |
| Data dir | `/home/workspace` | `/config` |
