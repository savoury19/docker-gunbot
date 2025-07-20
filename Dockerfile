FROM --platform=linux/amd64 debian:bookworm-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Download and extract Gunbot
RUN curl -L -o gunthy_linux.zip https://gunthy.org/downloads/gunthy_linux.zip && \
    unzip gunthy_linux.zip && \
    rm gunthy_linux.zip && \
    chmod +x gunthy-linux

# Optional: Create persistent userdata folder
RUN mkdir -p /app/gbuserdata

# Expose web GUI port
EXPOSE 5010

# Start Gunbot
ENTRYPOINT ["./gunthy-linux"]
