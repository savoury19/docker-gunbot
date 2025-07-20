FROM debian:bookworm-slim

ENV GBINSTALLLOC="/opt/gunbot"
ENV GBMOUNT="/mnt/gunbot"
ENV GBPORT=5010

WORKDIR ${GBINSTALLLOC}

RUN apt-get update \
 && apt-get install -y wget jq unzip openssl fontconfig ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${GBINSTALLLOC}" "${GBMOUNT}"

# Download Gunbot binary zip, trying both filenames (gunthy-linux.zip and gunthy_linux.zip)
# Replace these URLs with the exact ones you want to use for download
RUN set -eux; \
  echo "Downloading Gunbot binary..."; \
  wget -O gunthy.zip "https://your-download-location.com/gunthy-linux.zip" || true; \
  if [ ! -f gunthy.zip ] || [ ! -s gunthy.zip ]; then \
    echo "Trying alternate filename..."; \
    wget -O gunthy.zip "https://your-download-location.com/gunthy_linux.zip"; \
  fi; \
  unzip -o gunthy.zip -d . ; \
  rm -f gunthy.zip ; \
  chmod +x gunthy-linux

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# If you have a startup.sh locally, copy it; else create a simple one
COPY startup.sh ${GBINSTALLLOC}/startup.sh
RUN chmod +x ${GBINSTALLLOC}/startup.sh || echo "No startup.sh provided, using default"
RUN if [ ! -f ${GBINSTALLLOC}/startup.sh ]; then echo -e '#!/bin/bash\nexec ./gunthy-linux' > ${GBINSTALLLOC}/startup.sh && chmod +x ${GBINSTALLLOC}/startup.sh; fi

EXPOSE ${GBPORT}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "/opt/gunbot/startup.sh"]
