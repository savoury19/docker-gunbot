#!/bin/bash
set -e

# 1. Ensure persistent directories and symlinks
for d in json logs backups customStrategies user_modules; do
  mkdir -p "${GBMOUNT}/${d}"
  ln -sfn "${GBMOUNT}/${d}" "${GBINSTALLLOC}/${d}"
done

echo
echo "🔐 Cert/key files:"
for f in server.cert server.key; do
  if [ -f "./${f}" ]; then
    echo "👉 Overwriting ${f} from host."
    cp -f "./${f}" "${GBMOUNT}/${f}"
  elif [ -f "${GBINSTALLLOC}/${f}" ]; then
    echo "👉 Overwriting ${f} from image defaults."
    cp -f "${GBINSTALLLOC}/${f}" "${GBMOUNT}/${f}"
  else
    echo "⚠️ No ${f} found in host or image — skipping."
    continue
  fi
  ln -sfn "${GBMOUNT}/${f}" "${GBINSTALLLOC}/${f}"
done

echo
while true; do
  read -p "Overwrite config.js? (y/n): " yn
  case $yn in
    [Yy]* )
      if [ -f "./config.js" ]; then
        cp -f "./config.js" "${GBMOUNT}/config.js"
      elif [ -f "${GBINSTALLLOC}/config.js" ]; then
        cp -f "${GBINSTALLLOC}/config.js" "${GBMOUNT}/config.js"
      else
        echo "⚠️ No config.js found in host or container—skipping copy."
      fi
      ln -sfn "${GBMOUNT}/config.js" "${GBINSTALLLOC}/config.js"
      break;;
    [Nn]* )
      echo "❌ Skipping config.js overwrite."
      [ -f "${GBMOUNT}/config.js" ] && ln -sfn "${GBMOUNT}/config.js" "${GBINSTALLLOC}/config.js"
      break;;
    * ) echo "Please answer y or n.";;
  esac
done

echo
echo "🚀 Starting Gunbot..."
exec "$@"
