#!/bin/sh
set -e

mkdir -p /app/config

# 1. Копируем конфиги из Secret Files Render (ASF.json, bot.json и др.)
if [ -d /etc/secrets ]; then
  cp -f /etc/secrets/* /app/config/ 2>/dev/null || true
fi

# 2. Настраиваем IPC под порт Render (по умолчанию 10000)
PORT_TO_USE="${PORT:-10000}"
cat <<EOF > /app/config/IPC.config
{
  "Kestrel": {
    "Endpoints": {
      "HTTP": {
        "Url": "http://*:${PORT_TO_USE}"
      }
    }
  }
}
EOF

# Выдаем права пользователю asf (UID 1000), под которым работает сам процесс
chown -R 1000:1000 /app/config

# 3. Скрипт постоянной активности: пинг внешнего URL каждые 10 минут
if [ -n "$RENDER_EXTERNAL_URL" ]; then
  (
    sleep 60
    while true; do
      curl -fsS -m 15 "$RENDER_EXTERNAL_URL" >/dev/null 2>&1 || true
      sleep 600
    done
  ) &
fi

# 4. Запуск ASF
cd /app
if [ -f /app/ArchiSteamFarm.sh ]; then
  exec sh /app/ArchiSteamFarm.sh --no-restart --system-required
else
  exec ArchiSteamFarm --no-restart --system-required
fi