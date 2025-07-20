ARG DEBIANVERSION="bookworm-slim"
ARG GBACTIVATEBETA="0"

FROM --platform="linux/amd64" debian:${DEBIANVERSION} AS gunbot-builder
ARG GBACTIVATEBETA
ARG GBINSTALLLOC="/opt/gunbot"
ARG GBMOUNT="/mnt/gunbot"
ARG GBBETA="gunthy-linux.zip"

WORKDIR /tmp

RUN apt-get update && apt-get install -y wget jq unzip openssl && rm -rf /var/lib/apt/lists/* \
  \
  # Download & extract stable release
  && wget -q -nv -O gunthy_linux.zip https://gunthy.org/downloads/gunthy_linux.zip \
  && unzip -d . gunthy-linux.zip \
  && mv gunthy-linux gunbot \
  && rm gunthy-linux.zip \
  \
  # Optionally download & install beta if flagged
  && if [ "${GBACTIVATEBETA}" = "1" ]; then \
       wget -q -nv -O gunthy-linux-beta.zip https://gunthy.org/downloads/beta/gunthy-linux.zip && \
       unzip -o gunthy-linux-beta.zip && \
       mv -f gunthy-linux gunbot && \
       rm gunthy-linux-beta.zip; \
     fi \
  \
  # SSL configuration
  && printf "[req]\ndistinguished_name = req_distinguished_name\nprompt = no\n[req_distinguished_name]\ncommonName = localhost\n[v3_req]\nbasicConstraints = CA:FALSE\nsubjectKeyIdentifier = hash\nauthorityKeyIdentifier = keyid:always, issuer:always\nkeyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement\nextendedKeyUsage = serverAuth\nsubjectAltName = DNS:localhost\n" > gunbot/ssl.config \
  \
  # Generate startup.sh with checks
  && printf "#!/bin/bash\n" > gunbot/startup.sh \
  && printf "if [ -f ${GBMOUNT}/${GBBETA} ]; then unzip -d ${GBMOUNT} ${GBMOUNT}/${GBBETA}; mv ${GBMOUNT}/gunthy-linux ${GBINSTALLLOC}; fi\n" >> gunbot/startup.sh \
  && printf "if [ -f ${GBMOUNT}/ssl.config ]; then ln -sf ${GBMOUNT}/ssl.config ${GBINSTALLLOC}/ssl.config; fi\n" >> gunbot/startup.sh \
  && printf "if [ ! -f ${GBMOUNT}/localhost.crt ] && [ ! -f ${GBMOUNT}/localhost.key ]; then openssl req -config ${GBINSTALLLOC}/ssl.config -newkey rsa:2048 -nodes -keyout ${GBINSTALLLOC}/localhost.key -x509 -days 365 -out ${GBINSTALLLOC}/localhost.crt -extensions v3_req 2>/dev/null; else ln -sf ${GBMOUNT}/localhost.crt ${GBINSTALLLOC}/localhost.crt; fi\n" >> gunbot/startup.sh \
  \
  # Create & link persistent dirs
  && for d in json logs backups customStrategies user_modules; do \
       printf "if [ -L ${GBINSTALLLOC}/$d ]; then if [ ! -d ${GBMOUNT}/$d ]; then mkdir -p ${GBMOUNT}/$d; fi; else mkdir -p ${GBMOUNT}/$d; ln -sf ${GBMOUNT}/$d ${GBINSTALLLOC}/$d; fi\n" >> gunbot/startup.sh; \
     done \
  \
  # Ensure config files are present
  && for f in config.js UTAconfig.json autoconfig.json gunbotgui.db new_gui.sqlite; do \
       printf "if [ ! -f ${GBMOUNT}/$f ]; then cp ${GBINSTALLLOC}/$f ${GBMOUNT}/$f; fi; ln -sf ${GBMOUNT}/$f ${GBINSTALLLOC}/$f\n" >> gunbot/startup.sh; \
     done \
  \
  && chmod +x gunbot/startup.sh

################################################################################
FROM --platform="linux/amd64" debian:${DEBIANVERSION}
ARG MAINTAINER="savoury19"
ARG WEBSITE="https://gunthy.org/downloads/"
ARG DESCRIPTION
ARG GBINSTALLLOC="/opt/gunbot"
ARG GBMOUNT="/mnt/gunbot"
ARG GBPORT=5010

LABEL maintainer="${MAINTAINER}" website="${WEBSITE}" description="${DESCRIPTION:=Unofficial Gunbot Docker Container}"

RUN apt-get update && apt-get install -y chrony jq unzip openssl fontconfig && apt-get upgrade -y && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && mkdir -p "${GBMOUNT}"

COPY --from=gunbot-builder /tmp/gunbot ${GBINSTALLLOC}
WORKDIR ${GBINSTALLLOC}

# Ensure startup scripts are executable
RUN chmod +x startup.sh && [ -f custom.sh ] && chmod +x custom.sh || true && [ -f runner.sh ] && chmod +x runner.sh || true

EXPOSE ${GBPORT}
CMD ["bash","-c","${GBINSTALLLOC}/startup.sh"]
