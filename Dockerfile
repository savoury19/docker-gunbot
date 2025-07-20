FROM debian:bookworm-slim

# Set environment variables with default values
ENV GBINSTALLLOC="/opt/gunbot"
ENV GBMOUNT="/mnt/gunbot"
ENV GBPORT=5010

# Set working directory to where Gunbot will run from
WORKDIR ${GBINSTALLLOC}

# Install minimal dependencies
RUN apt-get update \
 && apt-get install -y wget jq unzip openssl fontconfig \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${GBINSTALLLOC}" "${GBMOUNT}"

# Copy the entrypoint script and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy Gunbot binary and startup script into the install location
COPY gunthy-linux "${GBINSTALLLOC}/gunthy-linux"
COPY startup.sh "${GBINSTALLLOC}/startup.sh"

# Optional: Ensure correct permissions
RUN chmod +x "${GBINSTALLLOC}/gunthy-linux" "${GBINSTALLLOC}/startup.sh"

# Expose Gunbot UI/API port
EXPOSE ${GBPORT}

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash", "/opt/gunbot/startup.sh"]
