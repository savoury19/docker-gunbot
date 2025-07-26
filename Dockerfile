FROM --platform=linux/amd64 debian:stable-slim

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

# Create required directories
RUN mkdir -p /opt/gunbot/json /app/gbuserdata && \
    ln -s /app/gbuserdata /opt/gunbot/json

# Expose Gunbot GUI and service ports
EXPOSE 3001 5001

# Set timezone via environment variable if needed
ENV TZ=Australia/Perth

# Start Gunbot
ENTRYPOINT ["./gunthy-linux"]
