ARG DEBIANVERSION="bookworm-slim"
ARG GBACTIVATEBETA=0
ARG GBINSTALLLOC="/opt/gunbot"
ARG GBUSERDATADIR="/app/gbuserdata"
ARG MAINTAINER="computeronix"
ARG DESCRIPTION="(Unofficial) Gunbot Docker Container"

# Builder stage
FROM --platform="linux/amd64" debian:${DEBIANVERSION} AS gunbot-builder

ARG GBACTIVATEBETA
ARG GBINSTALLLOC
ARG GBUSERDATADIR

WORKDIR /app

RUN apt-get update && apt-get install -y wget unzip \
  && rm -rf /var/lib/apt/lists/* \
  # Download stable build
  && wget -q -O gunbot.zip https://gunthy.org/downloads/gunthy_linux.zip \
  && unzip -d gunbot gunbot.zip \
  # Replace with beta build if activated
  && if [ "$GBACTIVATEBETA" = "1" ]; then \
       wget -q -O gunbot-beta.zip https://gunthy.org/downloads/beta/gunthy-linux.zip && \
       unzip -o -d gunbot gunbot-beta.zip ; \
     fi \
  && mv gunbot "${GBINSTALLLOC}" \
  # Create SSL config file
  && printf "[req]\ndistinguished_name = req_distinguished_name\nprompt = no\n[req_distinguished_name]\ncommonName = localhost\n[v3_req]\nbasicConstraints = CA:FALSE\nsubjectKeyIdentifier = hash\nauthorityKeyIdentifier = keyid:always, issuer:always\nkeyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement\nextendedKeyUsage = serverAuth\nsubjectAltName = DNS:localhost\n" > "${GBINSTALLLOC}/ssl.config" \
  # Create startup.sh script
  && printf '#!/bin/bash\n' > "${GBINSTALLLOC}/startup.sh" \
  && printf "mkdir -p ${GBUSERDATADIR}/json\n" >> "${GBINSTALLLOC}/startup.sh" \
  && printf "if [ ! -L ${GBINSTALLLOC}/json ]; then ln -sf ${GBUSERDATADIR}/json ${GBINSTALLLOC}/json; fi\n" >> "${GBINSTALLLOC}/startup.sh" \
  && printf "if [ ! -f ${GBUSERDATADIR}/config.js ]; then cp ${GBINSTALLLOC}/config.js ${GBUSERDATADIR}/config.js; fi\n" >> "${GBINSTALLLOC}/startup.sh" \
  && printf "ln -sf ${GBUSERDATADIR}/config.js ${GBINSTALLLOC}/config.js\n" >> "${GBINSTALLLOC}/startup.sh" \
  && printf "if [ ! -f ${GBINSTALLLOC}/localhost.key ] || [ ! -f ${GBINSTALLLOC}/localhost.crt ]; then \
      openssl req -config ${GBINSTALLLOC}/ssl.config -newkey rsa:2048 -nodes -keyout ${GBINSTALLLOC}/localhost.key -x509 -days 365 -out ${GBINSTALLLOC}/localhost.crt -extensions v3_req; \
     fi\n" >> "${GBINSTALLLOC}/startup.sh" \
  && printf "${GBINSTALLLOC}/gunthy-linux\n" >> "${GBINSTALLLOC}/startup.sh" \
  && chmod +x ${GBINSTALLLOC}/startup.sh

# Runtime stage
FROM --platform="linux/amd64" debian:${DEBIANVERSION}

ARG MAINTAINER
ARG DESCRIPTION
ARG GBINSTALLLOC
ARG GBUSERDATADIR

ENV TZ=Australia/Perth
ENV GUNBOTLOCATION=${GBINSTALLLOC}

LABEL maintainer="${MAINTAINER}" \
      description="${DESCRIPTION}"

COPY --from=gunbot-builder ${GBINSTALLLOC} ${GBINSTALLLOC}

WORKDIR /app

RUN apt-get update && apt-get install -y chrony jq unzip openssl fontconfig tzdata \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && apt-get upgrade -y && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && mkdir -p ${GBUSERDATADIR} ${GBUSERDATADIR}/json \
  && chmod +x ${GBINSTALLLOC}/startup.sh

# Ensure JSON symlink exists
RUN if [ ! -L ${GBINSTALLLOC}/json ]; then ln -sf ${GBUSERDATADIR}/json ${GBINSTALLLOC}/json; fi

EXPOSE 3001 5001

CMD ["bash", "-c", "${GUNBOTLOCATION}/startup.sh"]
