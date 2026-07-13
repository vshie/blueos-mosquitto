#!/bin/sh
set -eu

DATA_DIR="${MOSQUITTO_DATA:-/mosquitto/data}"
STATUS_PORT="${STATUS_PORT:-80}"
CONF="${MOSQUITTO_CONF:-/mosquitto/config/mosquitto.conf}"

mkdir -p "$DATA_DIR" /mosquitto/log
chown -R mosquitto:mosquitto /mosquitto/data /mosquitto/log 2>/dev/null || true

# Write a tiny runtime info file the status page can read
HOSTNAME_SAFE="$(hostname 2>/dev/null || echo blueos-mosquitto)"
cat > /www/runtime.json <<EOF
{
  "service": "blueos-mosquitto",
  "version": "0.1.0",
  "hostname": "${HOSTNAME_SAFE}",
  "mqtt_tcp": 1883,
  "mqtt_websockets": 9001,
  "anonymous": true
}
EOF

echo "Starting Mosquitto with ${CONF}"
mosquitto -c "$CONF" &
MQTT_PID=$!

echo "Starting status UI on :${STATUS_PORT}"
python3 -m http.server "$STATUS_PORT" --bind 0.0.0.0 --directory /www &
HTTP_PID=$!

shutdown() {
  echo "Shutting down..."
  kill "$MQTT_PID" "$HTTP_PID" 2>/dev/null || true
  wait "$MQTT_PID" "$HTTP_PID" 2>/dev/null || true
}
trap shutdown INT TERM

# Exit if either child dies
while kill -0 "$MQTT_PID" 2>/dev/null && kill -0 "$HTTP_PID" 2>/dev/null; do
  sleep 2
done

shutdown
exit 1
