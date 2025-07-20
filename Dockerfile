# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS builder

ARG GBACTIVATEBETA=0
ARG GBINSTALLLOC="/opt/gunbot"

WORKDIR /tmp

RUN apt-get update \
 && apt-get install -y wget unzip \
 && rm -rf /var/lib/apt/lists/* \
 \
 # Download stable release
 && wget -q -O gunthy-linux.zip https://gunthy.org/downloads/gunthy_linux.zip \
 && unzip gunthy-linux.zip \
 && mkdir -p "${GBINSTALLLOC}" \
 && mv gunthy-linux "${GBINSTALLLOC}" \
 && rm gunthy-linux.zip \
 \
 # Optionally download beta version
 && if [ "$GBACTIVATEBETA" = "1" ]; then \
      wget -q -O gunthy-linux-beta.zip https://gunthy.org/downloads/beta/gunthy-linux.zip && \
      unzip -o gunthy-linux-beta.zip && \
      mv -f gunthy-linux "${GBINSTALLLOC}" && \
      rm gunthy-linux-beta.zip; \
    fi

FROM debian:bookworm-slim

ENV GBINSTALLLOC="/opt/gunbot"
ENV GBMOUNT="/mnt/gunbot"
ENV GBPORT=5010

RUN apt-get update \
 && apt-get install -y chrony jq unzip openssl fontconfig \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${GBMOUNT}"

COPY --from=builder "${GBINSTALLLOC}" "${GBINSTALLLOC}"

WORKDIR "${GBINSTALLLOC}"

# entrypoint script to handle file setup
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE ${GBPORT}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "/opt/gunbot/startup.sh"]
