# BlueOS Mosquitto — MQTT Broker Extension

A BlueOS extension that runs an **[Eclipse Mosquitto](https://mosquitto.org/)**
MQTT broker on the onboard computer (Raspberry Pi 4 / Pi 5). It gives ESPHome
nodes, loggers, and dashboards a stable LAN bus for telemetry and control —
without requiring Home Assistant.

Use it as the first building block of a static-site stack:

```text
ESPHome devices  →  Mosquitto (this extension)  →  InfluxDB / Grafana (later)
```

A small status page is exposed on the extension’s HTTP port so you can confirm
the broker is up from the BlueOS **Extensions** UI (“Open”).

## Features

- **MQTT TCP on host port 1883** — point ESPHome `mqtt.broker` at the BlueOS
  Pi IP (or hostname on your LAN).
- **WebSockets on host port 9001** — optional for browser tools and future UI
  work.
- **Status page** on the dynamically mapped container port **80** (BlueOS
  “Open” link).
- **Persistent broker data** under `/usr/blueos/extensions/mosquitto` on the
  vehicle / site computer.
- **Multi-arch images** for Pi 4 (32-bit and 64-bit) and Pi 5 via GitHub Actions.

## Ports

| Port | Binding | Use |
|------|---------|-----|
| `1883` | Host `1883` | MQTT TCP (ESPHome, `mosquitto_sub`, Telegraf, …) |
| `9001` | Host `9001` | MQTT over WebSockets |
| `80` | Dynamic (`HostPort: ""`) | Status page (BlueOS sidebar Open) |

## Manual install on BlueOS

Open BlueOS → **Extensions** → **Installed** tab → **+** (bottom right) and fill
in the form exactly as below.

| Field | Value |
|-------|--------|
| **Extension Identifier** | `vshie.mosquitto` |
| **Extension Name** | `Mosquitto MQTT Broker` |
| **Docker image** | `vshie/blueos-mosquitto` |
| **Docker tag** | `main` |

> The Docker image is `vshie/blueos-mosquitto`. Use a released SemVer tag (e.g.
> `0.1.0`) instead of `main` once you tag a release — SemVer tags also get
> `:latest` from CI.

**Custom settings** — paste this JSON verbatim (stable MQTT ports + persistent
data bind; status UI on a BlueOS-assigned port):

```json
{
  "ExposedPorts": {
    "80/tcp": {},
    "1883/tcp": {},
    "9001/tcp": {}
  },
  "HostConfig": {
    "ExtraHosts": ["host.docker.internal:host-gateway"],
    "PortBindings": {
      "80/tcp": [
        {
          "HostPort": ""
        }
      ],
      "1883/tcp": [
        {
          "HostPort": "1883"
        }
      ],
      "9001/tcp": [
        {
          "HostPort": "9001"
        }
      ]
    },
    "Binds": [
      "/usr/blueos/extensions/mosquitto:/mosquitto/data"
    ]
  }
}
```

After it installs and starts, the extension appears in the BlueOS sidebar.
Open it to view the status page. From a laptop on the same network:

```bash
mosquitto_sub -h <blueos-ip> -t '#' -v
mosquitto_pub -h <blueos-ip> -t 'test/hello' -m 'ping'
```

### ESPHome

On the device YAML (broker = BlueOS Pi address on your LAN):

```yaml
mqtt:
  broker: 192.168.1.x
  discovery: false
  topic_prefix: blueos/relay
```

## Building / releasing

Pushing to `main` (or a git tag) triggers `.github/workflows/deploy.yml`, which
uses
[`BlueOS-community/Deploy-BlueOS-Extension`](https://github.com/BlueOS-community/Deploy-BlueOS-Extension)
to build and push multi-arch images to Docker Hub.

| Platform | Hardware |
|----------|----------|
| `linux/arm/v7` | Raspberry Pi 4, 32-bit BlueOS |
| `linux/arm64/v8` | Raspberry Pi 4 64-bit + **Raspberry Pi 5** |
| `linux/amd64` | Desktop / CI smoke |

Repository secrets: `DOCKER_USERNAME`, `DOCKER_PASSWORD` (Docker Hub).

Published as: **`vshie/blueos-mosquitto:<branch-or-tag>`**.

## Provenance / credits

This is **not** a fork of the official
[`eclipse-mosquitto`](https://hub.docker.com/_/eclipse-mosquitto) Docker Hub
image.

| Layer | Source |
|-------|--------|
| Base OS | [`alpine:3.21`](https://hub.docker.com/_/alpine) |
| Broker | Alpine package `mosquitto` → upstream **[Eclipse Mosquitto](https://mosquitto.org/)** |
| This repo | BlueOS wrapper (config, entrypoint, status UI, permissions labels) |

The official Hub image does not publish `linux/arm/v7`; Alpine’s package does,
which keeps Pi 4 32-bit BlueOS supported alongside Pi 5.

Eclipse Mosquitto is dual-licensed under the
[EPL-2.0](https://www.eclipse.org/legal/epl-2.0/) and
[EDL-1.0](https://www.eclipse.org/org/documents/edl-v10.php). Alpine Linux is
[MIT](https://www.alpinelinux.org/).

## v0.1 notes

- Anonymous publish/subscribe on the LAN (add a password file in a later
  release).
- No TLS yet — suitable for an isolated site / vehicle network; **do not**
  expose port 1883 to the public internet.

## Local development

```bash
docker build -t blueos-mosquitto:local .
docker run --rm -p 1883:1883 -p 9001:9001 -p 8080:80 blueos-mosquitto:local
# open http://localhost:8080
```

## License

Extension packaging: same community / BlueOS extension conventions as other
`vshie` BlueOS images. Upstream Mosquitto remains under EPL-2.0 / EDL-1.0.
