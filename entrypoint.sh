#!/bin/bash
set -e

echo "📁 Setting up persistent directories and symlinks..."
for d in json logs backups customStrategies user_modules; do
  mkdir -p "${GBMOUNT}/${d}"
  ln -sfn "${GBMOUNT}/${d}" "${GBINSTALLLOC}/${d}"
done

echo
echo "🔐 Handling SSL cert/key files..."
for f in server.cert server.key; do
  if [ -f "./${f}" ]; then
    echo "👉 Found ${f} in host dir, copying to persistent mount."
    cp -f "./${f}" "${GBMOUNT}/${f}"
  elif [ -f "${GBINSTALLLOC}/${f}" ]; then
    echo "👉 Found ${f} in image, copying to persistent mount."
    cp -f "${GBINSTALLLOC}/${f}" "${GBMOUNT}/${f}"
  else
    echo "⚠️  ${f} not found — skipping."
    continue
  fi
  ln -sfn "${GBMOUNT}/${f}" "${GBINSTALLLOC}/${f}"
done

echo
while true; do
  read -p "❓ Overwrite config.js from host/image? (y/n): " yn
  case $yn in
    [Yy]* )
      if [ -f "./config.js" ]; then
        echo "✅ Copying config.js from host."
        cp -f "./config.js" "${GBMOUNT}/config.js"
      elif [ -f "${GBINSTALLLOC}/config.js" ]; then
        echo "✅ Copying config.js from image."
        cp -f "${GBINSTALLLOC}/config.js" "${GBMOUNT}/config.js"
      else
        echo "⚠️  No config.js found in host or image — skipping copy."
      fi
      ln -sfn "${GBMOUNT}/config.js" "${GBINSTALLLOC}/config.js"
      break
      ;;
    [Nn]* )
      echo "❌ Skipping config.js overwrite."
      [ -f "${GBMOUNT}/config.js" ] && ln -sfn "${GBMOUNT}/config.js" "${GBINSTALLLOC}/config.js"
      break
      ;;
    * )
      echo "Please answer y or n."
      ;;
  esac
done

echo
echo "🚀 Starting Gunbot..."
exec "$@"
