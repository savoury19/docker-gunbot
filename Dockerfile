# Use an official Debian as a parent image
FROM debian:bookworm-slim

# Set environment variables
ENV GBINSTALLLOC="/opt/gunbot"
ENV GBMOUNT="/mnt/gunbot"
ENV GBPORT=5010

# Set the working directory
WORKDIR ${GBINSTALLLOC}

# Install necessary packages
RUN apt-get update \
 && apt-get install -y wget jq unzip openssl fontconfig \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p "${GBMOUNT}"

# Copy the Gunbot files
COPY gunbot ${GBINSTALLLOC}

# Set the entrypoint with an inline shell script
ENTRYPOINT ["/bin/bash", "-c", "
  set -e;

  # Ensure persistent directories exist and are symlinked
  for d in json logs backups customStrategies user_modules; do
    mkdir -p \"${GBMOUNT}/${d}\";
    ln -sfn \"${GBMOUNT}/${d}\" \"${GBINSTALLLOC}/${d}\";
  done;

  echo '';
  echo '🔐 Certificate and key files:';
  for f in server.cert server.key; do
    if [ -f \"./${f}\" ]; then
      echo \"👉 Overwriting ${f} from host.\";
      cp -f \"./${f}\" \"${GBMOUNT}/${f}\";
    else
      echo \"👉 Overwriting ${f} from image defaults.\";
      cp -f \"${GBINSTALLLOC}/${f}\" \"${GBMOUNT}/${f}\";
    fi;
    ln -sfn \"${GBMOUNT}/${f}\" \"${GBINSTALLLOC}/${f}\";
  done;

  echo '';
  # Ask user whether to overwrite config.js
  while true; do
    read -p \"Overwrite config.js? (y/n): \" yn;
    case \$yn in
      [Yy]* )
        if [ -f \"./config.js\" ]; then
          echo \"👉 Overwriting config.js from host.\";
          cp -f \"./config.js\" \"${GBMOUNT}/config.js\";
        else
          echo \"👉 Overwriting config.js from image defaults.\";
          cp -f \"${GBINSTALLLOC}/config.js\" \"${GBMOUNT}/config.js\";
        fi;
        ln -sfn \"${GBMOUNT}/config.js\" \"${GBINSTALLLOC}/config.js\";
        break;
        ;;
      [Nn]* )
        echo \"❌ Skipping config.js overwrite.\";
        # If it already exists in volume, good; otherwise leave image default in place
        if [ -f \"${GBMOUNT}/config.js\" ]; then
          ln -sfn \"${GBMOUNT}/config.js\" \"${GBINSTALLLOC}/config.js\";
        fi;
        break;
        ;;
      * ) echo \"Please enter y or n.\";;
    esac
  done;

  echo '';
  echo '🚀 Starting Gunbot...';
  exec \"$@\";
"]

# Default command
CMD ["bash", "/opt/gunbot/startup.sh"]
