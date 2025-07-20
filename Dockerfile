FROM debian:bookworm-slim

ENV GBINSTALLLOC="/opt/gunbot"
ENV GBMOUNT="/mnt/gunbot"
ENV GBPORT=5010

WORKDIR ${GBINSTALLLOC}

# Install dependencies and prepare environment
RUN apt-get update && apt-get install -y \
    wget jq unzip openssl fontconfig ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${GBINSTALLLOC}" "${GBMOUNT}"

# Download and install Gunbot binary
RUN wget -O gunthy.zip https://github.com/savoury19/gunbot-docker/raw/main/gunthy-linux.zip \
 && unzip gunthy.zip \
 && rm gunthy.zip \
 && chmod +x gunthy-linux || chmod +x gunthy_linux || true \
 && mv gunthy_linux gunthy-linux 2>/dev/null || true

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Fallback startup script
RUN echo '#!/bin/bash' > ${GBINSTALLLOC}/startup.sh \
 && echo 'exec ./gunthy-linux' >> ${GBINSTALLLOC}/startup.sh \
 && chmod +x ${GBINSTALLLOC}/startup.sh

EXPOSE ${GBPORT}
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "/opt/gunbot/startup.sh"]
