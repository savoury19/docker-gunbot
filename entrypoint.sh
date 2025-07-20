#!/bin/bash
set -e

# Ensure persistent directories exist and are symlinked
for d in json logs backups customStrategies user_modules; do
  mkdir -p "${GBMOUNT}/${d}"
  ln -sfn "${GBMOUNT}/${d}" "${GBINSTALLLOC}/${d}"
done

echo ""
echo "🔐 Certificate and key files:"
for f in server.cert server.key; do
  if [ -f "./${f}" ]; then
    echo "👉 Overwriting ${f} from host."
    cp -f "./${f}" "${GBMOUNT}/${f}"
  else
    echo "👉 Overwriting ${f} from image defaults."
    cp -f "${GBINSTALLLOC}/${f}" "${GBMOUNT}/${f}"
  fi
  ln -sfn "${GBMOUNT}/${f}" "${GBINSTALLLOC}/${f}"
done

echo ""
while true; do
  read -p "Overwrite config.js? (y/n): " yn
  case $yn in
    [Yy]* )
      if [ -f "./config.js" ]; then
        cp -f "./config.js" "${GBMOUNT}/config.js"
      else
        cp -f "${GBINSTALLLOC}/config.js" "${GBMOUNT}/config.js"
      fi
      ln -sfn "${GBMOUNT}/config.js" "${GBINSTALLLOC}/config.js"
      break;;
    [Nn]* )
      echo "Skipping config.js overwrite."
      [ -f "${GBMOUNT}/config.js" ] && ln -sfn "${GBMOUNT}/config.js" "${GBINSTALLLOC}/config.js"
      break;;
    * )
      echo "Please type y or n.";;
  esac
done

echo ""
echo "🚀 Starting Gunbot..."
exec "$@"
