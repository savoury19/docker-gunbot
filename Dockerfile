# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

ENV GBINSTALLLOC="/opt/gunbot"
ENV GBMOUNT="/mnt/gunbot"
ENV GBPORT=5010

WORKDIR ${GBINSTALLLOC}

RUN apt-get update \
 && apt-get install -y wget jq unzip openssl fontconfig \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${GBMOUNT}"

# Copy the application files
COPY gunbot ${GBINSTALLLOC}

# Copy and configure the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE ${GBPORT}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "/opt/gunbot/startup.sh"]
