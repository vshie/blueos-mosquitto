# BlueOS extension: Eclipse Mosquitto MQTT broker
# Multi-arch via Alpine (linux/arm/v7, linux/arm64/v8, linux/amd64)
# — covers Raspberry Pi 4 (32/64-bit BlueOS) and Pi 5 (arm64).

FROM alpine:3.21

ARG IMAGE_NAME=mosquitto
ARG AUTHOR="Tony White"
ARG AUTHOR_EMAIL="tony@bluerobotics.com"
ARG MAINTAINER="Tony White"
ARG MAINTAINER_EMAIL="tony@bluerobotics.com"
ARG REPO=vshie/blueos-mosquitto
ARG OWNER=vshie

RUN apk add --no-cache \
      mosquitto \
      mosquitto-clients \
      python3 \
 && mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log /www \
 && chown -R mosquitto:mosquitto /mosquitto

COPY config/mosquitto.conf /mosquitto/config/mosquitto.conf
COPY www/ /www/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV MOSQUITTO_DATA=/mosquitto/data
ENV STATUS_PORT=80

EXPOSE 80/tcp 1883/tcp 9001/tcp

LABEL version="0.1.0"
LABEL type="other"
LABEL tags='["mqtt","broker","esphome","automation","iot"]'
LABEL requirements="core >= 1.1"

LABEL permissions='\
{\
  "ExposedPorts": {\
    "80/tcp": {},\
    "1883/tcp": {},\
    "9001/tcp": {}\
  },\
  "HostConfig": {\
    "ExtraHosts": ["host.docker.internal:host-gateway"],\
    "PortBindings": {\
      "80/tcp": [{"HostPort": ""}],\
      "1883/tcp": [{"HostPort": "1883"}],\
      "9001/tcp": [{"HostPort": "9001"}]\
    },\
    "Binds": [\
      "/usr/blueos/extensions/mosquitto:/mosquitto/data"\
    ]\
  }\
}'

LABEL authors='[{"name": "Tony White", "email": "tony@bluerobotics.com"}]'
LABEL company='{\
  "about": "MQTT broker for ESPHome and BlueOS static-site telemetry",\
  "name": "Community",\
  "email": "tony@bluerobotics.com"\
}'
LABEL readme="https://raw.githubusercontent.com/${REPO}/{tag}/README.md"
LABEL links='{\
  "source": "https://github.com/vshie/blueos-mosquitto",\
  "documentation": "https://github.com/vshie/blueos-mosquitto/blob/main/README.md"\
}'

# Build-arg metadata (Deploy-BlueOS-Extension injects these)
LABEL org.blueos.image-name="${IMAGE_NAME}"
LABEL org.blueos.authors="[{\"name\": \"${AUTHOR}\", \"email\": \"${AUTHOR_EMAIL}\"}]"
LABEL org.blueos.company="{\"about\": \"MQTT broker for ESPHome and BlueOS\", \"name\": \"${MAINTAINER}\", \"email\": \"${MAINTAINER_EMAIL}\"}"

WORKDIR /mosquitto
ENTRYPOINT ["/entrypoint.sh"]
