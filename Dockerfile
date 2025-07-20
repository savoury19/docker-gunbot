FROM debian:bookworm-slim

# Environment setup
ENV GBINSTALLLOC="/opt/gunbot"
ENV GBMOUNT="/mnt/gunbot"
ENV GBPORT=5010

# Set working directory to Gunbot install location
WORKDIR ${GBINSTALLLOC}

# Install dependencies
RUN apt-get update \
 && apt-get install -y wget jq unzip openssl fontconfig ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${GBINSTALLLOC}" "${GBMOUNT}"

# Download and unzip gunthy-linux binary
# 🔁 Replace the URLs below with your actual working download locations
RUN set -eux; \
  echo "📥 Downloading gunthy-linux.zip..."; \
  wget -O gunthy.zip "https://github.com/GuntharDeNiro/BTCT/releases/latest/download/gunthy-linux.zip" || \
  wget -O gunthy.zip "https://github.com/GuntharDeNiro/BTCT/releases/latest/download/gunthy_linux.zip"; \
  echo "📦 Extracting..."; \
  unzip -o gunthy.zip -d .; \
  rm -f gunthy.zip; \
  chmod +x ./gunthy-linux

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Optional: copy or create a startup.sh
COPY startup.sh ${GBINSTALLLOC}/startup.sh
RUN chmod +x ${GBINSTALLLOC}/startup.sh || echo "No startup.sh provided, using default"

# Fallback: create a basic startup.sh if none exists
RUN if [ ! -f ${GBINSTALLLOC}/startup.sh ]; then \
      echo '#!/bin/bash' > ${GBINSTALLLOC}/startup.sh && \
      echo 'exec ./gunthy-linux' >> ${GBINSTALLLOC}/startup.sh && \
      chmod +x ${GBINSTALLLOC}/startup.sh; \
    fi

# Expose Gunbot web UI/API port
EXPOSE ${GBPORT}

# Entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "/opt/gunbot/startup.sh"]
