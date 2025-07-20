FROM debian:bookworm-slim

ENV GBINSTALLLOC="/opt/gunbot"
ENV GBMOUNT="/mnt/gunbot"
ENV GBPORT=5010

WORKDIR ${GBINSTALLLOC}

# Install dependencies
RUN apt-get update \
 && apt-get install -y wget jq unzip openssl fontconfig \
 && rm -rf /var/lib/apt/lists/*

# Download and unpack Gunbot binary
RUN wget -O gunthy.zip https://gunthy.org/downloads/gunthy_linux.zip \
 && unzip gunthy.zip \
 && rm gunthy.zip \
 && chmod +x gunthy-linux || chmod +x gunthy_linux \
 && ln -s gunthy-linux gunthy || ln -s gunthy_linux gunthy

# Create mount and install locations
RUN mkdir -p "${GBMOUNT}"

# Copy startup and entrypoint scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Fallback startup.sh if none is mounted
RUN echo '#!/bin/bash' > ${GBINSTALLLOC}/startup.sh && \
    echo 'echo "🚀 Starting Gunbot from startup.sh..."' >> ${GBINSTALLLOC}/startup.sh && \
    echo 'ls -l' >> ${GBINSTALLLOC}/startup.sh && \
    echo 'if [ -x ./gunthy-linux ]; then exec ./gunthy-linux; elif [ -x ./gunthy_linux ]; then exec ./gunthy_linux; else echo "❌ gunthy binary not found"; sleep 30; fi' >> ${GBINSTALLLOC}/startup.sh && \
    chmod +x ${GBINSTALLLOC}/startup.sh

EXPOSE ${GBPORT}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "/opt/gunbot/startup.sh"]
