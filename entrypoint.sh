#!/bin/bash
set -e

# Set default values if not provided
: "${GBMOUNT:=/mnt/gunbot}"
: "${GBINSTALLLOC:=/opt/gunbot}"

echo "🔧 Creating persistent directories and symlinks..."
for d in json logs backups customStrategies user_modules; do
  mkdir -p "${GBMOUNT}/${d}"
  ln -sfn "${GBMOUNT}/${d}" "${GBINSTALLLOC}/${d}"
done

echo
echo "🔐 Setting up certificate and key files..."
for f in server.cert server.key; do
  if [ -f "./${f}" ]; then
    echo "👉 Copying ${f} from host to volume."
    cp -f "./${f}" "${GBMOUNT}/${f}"
  elif [ -f "${GBINSTALLLOC}/${f}" ]; then
    echo "👉 Copying ${f} from image defaults to volume."
    cp -f "${GBINSTALLLOC}/${f}" "${GBMOUNT}/${f}"
  else
    echo "⚠️ No ${f} found — skipping."
    continue
  fi
  ln -sfn "${GBMOUNT}/${f}" "${GBINSTALLLOC}/${f}"
done

echo
echo "⚙️  Handling config.js setup..."

# Handle interactive or automated overwrite of config.js
OVERWRITE_MODE="${OVERWRITE_CONFIG:-ask}"  # yes / no / ask

if [[ "$OVERWRITE_MODE" == "yes" ]]; then
  yn="y"
elif [[ "$OVERWRITE_MODE" == "no" ]]; then
  yn="n"
else
  echo
  echo "📝 config.js found. You can choose to overwrite it from:"
  echo "   - Host path: ./config.js"
  echo "   - Container image: ${GBINSTALLLOC}/config.js"
  echo "   - Or skip and use existing volume copy (if any)"
  echo
  while true; do
    read -p "❓ Overwrite config.js in mounted volume? (y/n): " yn
    case "$yn" in
      [YyNn]*) break ;;
      *) echo "⛔ Please enter 'y' or 'n'." ;;
    esac
  done
fi

if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
  if [ -f "./config.js" ]; then
    echo "✅ Copying config.js from host to volume."
    cp -f "./config.js" "${GBMOUNT}/config.js"
  elif [ -f "${GBINSTALLLOC}/config.js" ]; then
    echo "✅ Copying config.js from image to volume."
    cp -f "${GBINSTALLLOC}/config.js" "${GBMOUNT}/config.js"
  else
    echo "⚠️ No config.js found — skipping copy."
  fi
else
  echo "❌ Skipping config.js overwrite."
fi

# Always link if it exists in volume
[ -f "${GBMOUNT}/config.js" ] && ln -sfn "${GBMOUNT}/config.js" "${GBINSTALLLOC}/config.js"

echo
echo "🚀 Launching Gunbot..."
exec "$@"
