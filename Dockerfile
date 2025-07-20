ARG DEBIANVERSION="bookworm-slim"
ARG GBACTIVATEBETA="0"

FROM --platform="linux/amd64" debian:${DEBIANVERSION} AS builder

# Install dependencies in a single layer
RUN apt-get update && \
    apt-get install -y wget jq unzip openssl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Download and extract the stable release
RUN wget -q -nv -O gunthy_linux.zip https://gunthy.org/downloads/gunthy_linux.zip && \
    unzip gunthy_linux.zip && \
    mv gunthy_linux gunbot && \
    rm gunthy_linux.zip

# Optionally switch to beta build if flagged
RUN if [ "${GBACTIVATEBETA}" = "1" ]; then \
      wget -q -nv -O gunthy-linux-beta.zip https://gunthy.org/downloads/beta/gunthy-linux.zip && \
      unzip -o gunthy-linux-beta.zip && \
      mv -f gunthy-linux gunbot && \
      rm gunthy-linux-beta.zip; \
    fi

# Create SSL config + startup.sh (example snippet)
RUN cd gunbot && \
    printf "[req]\ndistinguished_name = req_distinguished_name\nprompt = no\n[req_distinguished_name]\ncommonName = localhost\n" > ssl.config && \
    printf "#!/bin/bash\n# … your startup logic here …\n" > startup.sh && \
    chmod +x startup.sh

################################################################################
# Final runtime image
FROM --platform="linux/amd64" debian:${DEBIANVERSION}

ARG GBACTIVATEBETA
ARG GBPORT=5010

RUN apt-get update && \
    apt-get install -y chrony jq unzip openssl fontconfig && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy built files
COPY --from=builder /tmp/gunbot /opt/gunbot

WORKDIR /opt/gunbot

ENV GUNBOTLOCATION="/opt/gunbot"

EXPOSE ${GBPORT}

CMD ["bash", "/opt/gunbot/startup.sh"]
