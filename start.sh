#!/bin/sh
set -e

mkdir -p /app/config

# Копируем конфиги из Secret Files Render (ASF.json, main.json и т.д.)
if [ -d /etc/secrets ]; then
  cp -f /etc/secrets/* /app/config/ 2>/dev/null || true
fi

# Настраиваем IPC под порт Render и доверенные подсети прокси
PORT_TO_USE="${PORT:-10000}"
cat <<EOF > /app/config/IPC.config
{
  "Kestrel": {
    "Endpoints": {
      "HTTP": {
        "Url": "http://*:${PORT_TO_USE}"
      }
    },
    "KnownNetworks": [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16"
    ]
  }
}
EOF

chown -R 1000:1000 /app/config

# Внутренний пинг внешнего URL каждые 10 минут
if [ -n "$RENDER_EXTERNAL_URL" ]; then
  (
    sleep 60
    while true; do
      curl -fsS -m 15 "$RENDER_EXTERNAL_URL" >/dev/null 2>&1 || true
      sleep 600
    done
  ) &
fi

# Запуск ASF
cd /app
if [ -f /app/ArchiSteamFarm.sh ]; then
  exec sh /app/ArchiSteamFarm.sh --no-restart
else
  exec ArchiSteamFarm --no-restart
fi
