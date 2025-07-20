ARG DEBIANVERSION="bookworm-slim"
ARG GUNBOTVERSION="latest"
ARG GITHUBOWNER="GuntharDeNiro"
ARG GITHUBREPO="BTCT"
ARG GITHUBOWNERBETA="savoury19"
ARG GITHUBREPOBETA="BTCT-Beta"
ARG GUNBOTBETAVERSION="latest"
ARG GBINSTALLLOC="/opt/gunbot"
ARG GBMOUNT="/mnt/gunbot"
ARG GBACTIVATEBETA
ARG GBBETA="gunthy-linux.zip"
ARG GBPORT=5010
ARG MAINTAINER="savoury19"
ARG WEBSITE="https://gunthy.org/downloads/"
ARG DESCRIPTION="(Unofficial) Gunbot Docker Container - ${GUNBOTVERSION}"

#SCRATCH WORKSPACE FOR BUILDING IMAGE
FROM --platform="linux/amd64" debian:${DEBIANVERSION} AS gunbot-builder
ARG GUNBOTVERSION
ARG GITHUBOWNER
ARG GITHUBREPO
ARG GBINSTALLLOC
ARG GITHUBOWNERBETA
ARG GITHUBREPOBETA
ARG GUNBOTBETAVERSION
ARG GBACTIVATEBETA
ARG GBBETA
ARG GBMOUNT
ARG GBPORT

WORKDIR /tmp

#BUILDING IMAGE
#update mirrors and install packages
RUN apt-get update && apt-get install -y wget jq unzip \
  #remove mirrors
  && rm -rf /var/lib/apt/lists/* \
  #pull ${GUNBOTVERSION} from official Gunbot site.
  && wget -q -nv -O gunthy_linux.zip $(wget -q -nv -O- https://gunthy.org/downloads/gunthy_linux.zip
   unzip -d . gunthy_linux.zip \
  && mv gunthy_linux gunbot \
  #check for gunbot beta activation
  && if [ "$GBACTIVATEBETA" = 1 ]; then \
    wget -q -nv -O https://gunthy.org/downloads/beta/gunthy-linux.zip
    mv -f gunthy-linux gunbot ; \
  fi \
  #create self-signed ssl configuratuon
  && printf "[req]\n" > gunbot/ssl.config \
  && printf "distinguished_name = req_distinguished_name\n" >> gunbot/ssl.config \
  && printf "prompt = no\n" >> gunbot/ssl.config \
  && printf "[req_distinguished_name]\n" >> gunbot/ssl.config \
  && printf "commonName = localhost\n" >> gunbot/ssl.config \
  && printf "[ v3_req ]\n" >> gunbot/ssl.config \
  && printf "basicConstraints = CA:FALSE\n" >> gunbot/ssl.config \
  && printf "subjectKeyIdentifier = hash\n" >> gunbot/ssl.config \
  && printf "authorityKeyIdentifier = keyid:always, issuer:always\n" >> gunbot/ssl.config \
  && printf "keyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement\n" >> gunbot/ssl.config \
  && printf "extendedKeyUsage = serverAuth\n" >> gunbot/ssl.config \
  && printf "subjectAltName = DNS:localhost\n" >> gunbot/ssl.config \
  #create startup.sh bash script
  && printf "#!/bin/bash\n" > gunbot/startup.sh \
  #check for Gunbot Beta (${GBBETA}) directory
  && printf "if [ -f ${GBMOUNT}/${GBBETA} ]; then \n" >> gunbot/startup.sh \
  && printf "	unzip -d ${GBMOUNT} ${GBMOUNT}/${GBBETA}\n" >> gunbot/startup.sh \
  && printf "	mv ${GBMOUNT}/gunthy-linux ${GBINSTALLLOC}\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  #check for ssl.config
  && printf "if [ -f ${GBMOUNT}/ssl.config ]; then \n" >> gunbot/startup.sh \
  && printf "	ln -sf ${GBMOUNT}/ssl.config ${GBINSTALLLOC}/ssl.config\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  #check for localhost.crt AND localhost.key
  && printf "if [ ! -f ${GBMOUNT}/localhost.crt ] && [ ! -f ${GBMOUNT}/localhost.key ]; then \n" >> gunbot/startup.sh \
  && printf "	openssl req -config ${GBINSTALLLOC}/ssl.config -newkey rsa:2048 -nodes -keyout ${GBINSTALLLOC}/localhost.key -x509 -days 365 -out ${GBINSTALLLOC}/localhost.crt -extensions v3_req 2>/dev/null \n" >> gunbot/startup.sh \
  && printf "else\n" >> gunbot/startup.sh \
  && printf "   ln -sf ${GBMOUNT}/localhost.crt ${GBINSTALLLOC}/localhost.crt\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  #triple check json directory is linked
  && printf "if [ -L ${GBINSTALLLOC}/json ] ; then\n" >> gunbot/startup.sh \
  && printf "   if [ -d ${GBMOUNT}/json ] ; then\n" >> gunbot/startup.sh \
  && printf "      echo Good link >/dev/null \n" >> gunbot/startup.sh \
  && printf "   else\n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/json\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "else\n" >> gunbot/startup.sh \
  && printf "   if [ ! -d ${GBMOUNT}/json ]; then \n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/json\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "   ln -sf ${GBMOUNT}/json ${GBINSTALLLOC}/json\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  #triple check logs directory is linked
  && printf "if [ -L ${GBINSTALLLOC}/logs ] ; then\n" >> gunbot/startup.sh \
  && printf "   if [ -d ${GBMOUNT}/logs ] ; then\n" >> gunbot/startup.sh \
  && printf "      echo Good link >/dev/null \n" >> gunbot/startup.sh \
  && printf "   else\n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/logs\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "else\n" >> gunbot/startup.sh \
  && printf "   if [ ! -d ${GBMOUNT}/logs ]; then \n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/logs\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "   ln -sf ${GBMOUNT}/logs ${GBINSTALLLOC}/logs\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  #triple check backups directory is linked
  && printf "if [ -L ${GBINSTALLLOC}/backups ] ; then\n" >> gunbot/startup.sh \
  && printf "   if [ -d ${GBMOUNT}/backups ] ; then\n" >> gunbot/startup.sh \
  && printf "      echo Good link >/dev/null \n" >> gunbot/startup.sh \
  && printf "   else\n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/backups\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "else\n" >> gunbot/startup.sh \
  && printf "   if [ ! -d ${GBMOUNT}/backups ]; then \n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/backups\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "   ln -sf ${GBMOUNT}/backups ${GBINSTALLLOC}/backups\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  #triple check customStrategies directory is linked
  && printf "if [ -L ${GBINSTALLLOC}/customStrategies ] ; then\n" >> gunbot/startup.sh \
  && printf "   if [ -d ${GBMOUNT}/customStrategies ] ; then\n" >> gunbot/startup.sh \
  && printf "      echo Good link >/dev/null \n" >> gunbot/startup.sh \
  && printf "   else\n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/customStrategies\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "else\n" >> gunbot/startup.sh \
  && printf "   if [ ! -d ${GBMOUNT}/customStrategies ]; then \n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/customStrategies\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "   ln -sf ${GBMOUNT}/customStrategies ${GBINSTALLLOC}/customStrategies\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  #triple check user_modules directory is linked and not empty
  && printf "if [ -L ${GBINSTALLLOC}/user_modules ] ; then\n" >> gunbot/startup.sh \
  && printf "   if [ -d ${GBMOUNT}/user_modules ] ; then\n" >> gunbot/startup.sh \
  && printf "      echo Good link >/dev/null \n" >> gunbot/startup.sh \
  && printf "   else\n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/user_modules\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "else\n" >> gunbot/startup.sh \
  && printf "   if [ ! -d ${GBMOUNT}/user_modules ]; then \n" >> gunbot/startup.sh \
  && printf "	     mkdir ${GBMOUNT}/user_modules\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "   if [ ! -z \"\$(ls -A ${GBINSTALLLOC}/user_modules 2>/dev/null)\" ]; then \n" >> gunbot/startup.sh \
  && printf "	     echo Not empty >/dev/null \n" >> gunbot/startup.sh \
  && printf "   else\n" >> gunbot/startup.sh \
  && printf "      ln -sf ${GBMOUNT}/user_modules ${GBINSTALLLOC}/user_modules\n" >> gunbot/startup.sh \
  && printf "   fi\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  #check for config.js file
  && printf "if [ ! -f ${GBMOUNT}/config.js ]; then \n" >> gunbot/startup.sh \
  && printf "	cp ${GBINSTALLLOC}/config.js ${GBMOUNT}/config.js\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  && printf "ln -sf ${GBMOUNT}/config.js ${GBINSTALLLOC}/config.js\n" >> gunbot/startup.sh \
  #check for UTAconfig.json file
  && printf "if [ ! -f ${GBMOUNT}/UTAconfig.json ]; then \n" >> gunbot/startup.sh \
  && printf "	cp ${GBINSTALLLOC}/UTAconfig.json ${GBMOUNT}/UTAconfig.json\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  && printf "ln -sf ${GBMOUNT}/UTAconfig.json ${GBINSTALLLOC}/UTAconfig.json\n" >> gunbot/startup.sh \
  #check for autoconfig.json file
  && printf "if [ ! -f ${GBMOUNT}/autoconfig.json ]; then \n" >> gunbot/startup.sh \
  && printf "	cp ${GBINSTALLLOC}/autoconfig.json ${GBMOUNT}/autoconfig.json\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  && printf "ln -sf ${GBMOUNT}/autoconfig.json ${GBINSTALLLOC}/autoconfig.json\n" >> gunbot/startup.sh \
  #check for gunbotgui.db file
  && printf "if [ ! -f ${GBMOUNT}/gunbotgui.db ]; then \n" >> gunbot/startup.sh \
  && printf "	touch ${GBINSTALLLOC}/gunbotgui.db\n" >> gunbot/startup.sh \
  && printf "	cp ${GBINSTALLLOC}/gunbotgui.db ${GBMOUNT}/gunbotgui.db\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  && printf "ln -sf ${GBMOUNT}/gunbotgui.db ${GBINSTALLLOC}/gunbotgui.db\n" >> gunbot/startup.sh \
  #check for new_gui.sqlite file
  && printf "if [ ! -f ${GBMOUNT}/new_gui.sqlite ]; then \n" >> gunbot/startup.sh \
  && printf "	touch ${GBINSTALLLOC}/new_gui.sqlite\n" >> gunbot/startup.sh \
  && printf "	cp ${GBINSTALLLOC}/new_gui.sqlite ${GBMOUNT}/new_gui.sqlite\n" >> gunbot/startup.sh \
  && printf "fi\n" >> gunbot/startup.sh \
  && printf "ln -sf ${GBMOUNT}/new_gui.sqlite ${GBINSTALLLOC}/new_gui.sqlite\n" >> gunbot/startup.sh \
  
#BUILD THE RUN IMAGE
FROM --platform="linux/amd64" debian:${DEBIANVERSION}
ARG MAINTAINER
ARG WEBSITE
ARG DESCRIPTION
ARG GBINSTALLLOC
ARG GBBETA
ARG GBPORT
ARG GBMOUNT
ENV GUNBOTLOCATION=${GBINSTALLLOC}

LABEL \
  maintainer="${MAINTAINER}" \
  website="${WEBSITE}" \
  description="${DESCRIPTION}"

COPY --from=gunbot-builder /tmp/gunbot ${GBINSTALLLOC}

WORKDIR ${GBINSTALLLOC}

RUN apt-get update && apt-get install -y chrony jq unzip openssl fontconfig \
  && apt-get upgrade -y \
  && apt-get autoremove -y \
  && apt-get autoclean -y \
  && rm -rf /var/lib/apt/lists/* \
  #&& useradd -u 1000 gunbotuser \
  #&& chown -R 1000:1000 "${GBINSTALLLOC}" \
  && mkdir "${GBMOUNT}" \
  #&& chown -R 1000:1000 "${GBMOUNT}" \
  && chmod +x "${GBINSTALLLOC}/startup.sh" \
  && chmod +x "${GBINSTALLLOC}/custom.sh" \
  && chmod +x "${GBINSTALLLOC}/runner.sh"

#USER gunbotuser

EXPOSE ${GBPORT}
CMD ["bash","-c","${GUNBOTLOCATION}/startup.sh"]
