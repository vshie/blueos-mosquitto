# BlueOS Mosquitto

MQTT broker extension for BlueOS. First piece of the ESPHome-without-HA stack
(Mosquitto → InfluxDB → Grafana, plus an ESPHome builder later).

## Provenance / credits

This is **not** a fork of the official [`eclipse-mosquitto`](https://hub.docker.com/_/eclipse-mosquitto) Docker Hub image.

| Layer | Source |
|-------|--------|
| Base OS | [`alpine:3.21`](https://hub.docker.com/_/alpine) |
| Broker binary | Alpine package `mosquitto` → upstream **[Eclipse Mosquitto](https://mosquitto.org/)** ([GitHub](https://github.com/eclipse-mosquitto/mosquitto)) |
| This repo | New BlueOS wrapper (config, entrypoint, status UI, `LABEL permissions`) by `vshie` |

**Why not `FROM eclipse-mosquitto`?** The official Hub image does not publish `linux/arm/v7`. Alpine’s package does, which we need for Pi 4 32-bit BlueOS alongside Pi 4/5 `arm64`.

Eclipse Mosquitto is dual-licensed under the [Eclipse Public License 2.0](https://www.eclipse.org/legal/epl-2.0/) and [Eclipse Distribution License 1.0](https://www.eclipse.org/org/documents/edl-v10.php). This extension redistributes the broker via distro packages; keep upstream notices if you vendor sources later. Alpine Linux is [MIT](https://www.alpinelinux.org/).

## Install

Docker Hub image (after CI publishes):

```text
vshie/blueos-mosquitto
```

Tag: `main` (dev) or a SemVer tag like `0.1.0`.

In BlueOS → Extensions → install from image name, or add to your extensions store.

**Published ports**

| Port | Use |
|------|-----|
| `1883` | MQTT TCP (ESPHome, Telegraf, tools) |
| `9001` | MQTT over WebSockets |
| dynamic `80` | Status page (BlueOS “Open”) |

Persistence: `/usr/blueos/extensions/mosquitto` on the Pi.

## Architectures

GitHub Actions builds:

- `linux/arm/v7` — Raspberry Pi 4 32-bit BlueOS
- `linux/arm64/v8` — Raspberry Pi 4 64-bit + **Pi 5**
- `linux/amd64` — desktop / CI smoke

Base is Alpine + `apk add mosquitto` (not the official `eclipse-mosquitto` image alone),
so armv7 is available.

## ESPHome

On your node YAML:

```yaml
mqtt:
  broker: 192.168.1.x   # BlueOS Pi IP on paka oluolu
  topic_prefix: blueos/relay
```

Leave discovery off unless you want Home Assistant-style discovery topics.

## Test from a laptop

```bash
mosquitto_sub -h <blueos-ip> -t '#' -v
mosquitto_pub -h <blueos-ip> -t 'test/hello' -m 'ping'
```

## v0.1 notes

- Anonymous publish/subscribe on the LAN (tighten with a password file later).
- No TLS yet — fine for an isolated site VLAN; do not expose 1883 to the internet.

## Develop locally

```bash
docker build -t blueos-mosquitto:local .
docker run --rm -p 1883:1883 -p 9001:9001 -p 8080:80 blueos-mosquitto:local
# open http://localhost:8080
```

## Related

Plan of plans: see `BlueOS-HA-node/PLAN.md` on the workstation, or the static-site stack docs once published.
