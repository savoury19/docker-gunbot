FROM debian:bookworm-slim

ENV GBINSTALLLOC="/opt/gunbot"
ENV GBMOUNT="/mnt/gunbot"
ENV GBPORT=5010

WORKDIR ${GBINSTALLLOC}

# Install dependencies
RUN apt-get update \
 && apt-get install -y wget jq unzip openssl fontconfig ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${GBINSTALLLOC}" "${GBMOUNT}"

# Download Gunbot binary (adjust URL if needed)
RUN wget -O gunthy.zip https://gunthy.org/downloads/gunthy_linux.zip
 && unzip gunthy.zip \
 && rm gunthy.zip \
 && chmod +x gunthy_linux

# Add entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Add default startup.sh if none provided
RUN echo '#!/bin/bash' > ${GBINSTALLLOC}/startup.sh \
 && echo 'exec ./gunthy-linux' >> ${GBINSTALLLOC}/startup.sh \
 && chmod +x ${GBINSTALLLOC}/startup.sh

EXPOSE ${GBPORT}
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "/opt/gunbot/startup.sh"]
