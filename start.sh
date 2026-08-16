#!/usr/bin/env bash

set +e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

NODE_BIN="./.node/node-v22/bin/node"
if [ ! -x "$NODE_BIN" ]; then
  NODE_BIN="node"
else
  export PATH="$(pwd)/.node/node-v22/bin:$PATH"
fi

run_bot() {
  if command -v stdbuf >/dev/null 2>&1; then
    if [ "$1" = "sim" ]; then
      exec stdbuf -oL -eL "$NODE_BIN" ./ARQUIVES/connect.js sim
    elif [ "$1" = "não" ]; then
      exec stdbuf -oL -eL "$NODE_BIN" ./ARQUIVES/connect.js não
    else
      exec stdbuf -oL -eL "$NODE_BIN" ./ARQUIVES/connect.js
    fi
  else
    if [ "$1" = "sim" ]; then
      exec "$NODE_BIN" ./ARQUIVES/connect.js sim
    elif [ "$1" = "não" ]; then
      exec "$NODE_BIN" ./ARQUIVES/connect.js não
    else
      exec "$NODE_BIN" ./ARQUIVES/connect.js
    fi
  fi
}

printf "[%s] DENNYS BOT | iniciando processo...\n" "$(date '+%d/%m %H:%M:%S')"
printf "[%s] DENNYS BOT | node runtime: %s\n" "$(date '+%d/%m %H:%M:%S')" "$("$NODE_BIN" -v 2>/dev/null || echo indisponivel)"

# Menos atraso nos logs e bootstrap mais previsivel no PM2/Pterodactyl.
export NODE_ENV="production"
export TZ="America/Sao_Paulo"
export UV_THREADPOOL_SIZE="${UV_THREADPOOL_SIZE:-32}"
export NODE_OPTIONS="--dns-result-order=ipv4first ${NODE_OPTIONS}"

if [ ! -f "node_modules/@whiskeysockets/baileys/package.json" ]; then
  printf "[%s] DENNYS BOT | instalando dependencias ausentes...\n" "$(date '+%d/%m %H:%M:%S')"
  npm ci --omit=dev --ignore-scripts || exit 64
fi

AUTO_RESTART="${YUTA_AUTO_RESTART:-1}"
RESTART_DELAY=1
MAX_RESTART_DELAY=30
STABLE_RUNTIME_SECONDS=300
STOP_REQUESTED=0
CHILD_PID=""

request_stop() {
  STOP_REQUESTED=1
  if [ -n "$CHILD_PID" ] && kill -0 "$CHILD_PID" 2>/dev/null; then
    kill -TERM "$CHILD_PID" 2>/dev/null
  fi
}

trap request_stop INT TERM HUP

while :; do
  if [ "$STOP_REQUESTED" = "1" ]; then
    exit 0
  fi

  started_at="$(date +%s)"
  # Mantem o console do Wings ligado ao readline mesmo com o supervisor em segundo plano.
  run_bot "$1" <&0 &
  CHILD_PID=$!
  wait "$CHILD_PID"
  exit_code=$?
  CHILD_PID=""

  if [ "$STOP_REQUESTED" = "1" ]; then
    printf "[%s] DENNYS BOT | parada solicitada; supervisor encerrado.\n" "$(date '+%d/%m %H:%M:%S')"
    exit 0
  fi

  if [ "$exit_code" = "64" ] || [ "$exit_code" = "78" ]; then
    printf "[%s] DENNYS BOT | erro fatal de configuracao (%s); reinicio automatico bloqueado.\n" \
      "$(date '+%d/%m %H:%M:%S')" "$exit_code"
    exit "$exit_code"
  fi

  if [ "$AUTO_RESTART" != "1" ]; then
    printf "[%s] DENNYS BOT | processo finalizado com codigo %s.\n" "$(date '+%d/%m %H:%M:%S')" "$exit_code"
    exit "$exit_code"
  fi

  runtime_seconds=$(( $(date +%s) - started_at ))
  if [ "$runtime_seconds" -ge "$STABLE_RUNTIME_SECONDS" ]; then
    RESTART_DELAY=1
  fi

  printf "[%s] DENNYS BOT | processo finalizado com codigo %s; reiniciando em %ss...\n" \
    "$(date '+%d/%m %H:%M:%S')" "$exit_code" "$RESTART_DELAY"
  sleep "$RESTART_DELAY"

  if [ "$STOP_REQUESTED" = "1" ]; then
    printf "[%s] DENNYS BOT | parada solicitada durante a espera; supervisor encerrado.\n" "$(date '+%d/%m %H:%M:%S')"
    exit 0
  fi

  if [ "$runtime_seconds" -lt "$STABLE_RUNTIME_SECONDS" ] && [ "$RESTART_DELAY" -lt "$MAX_RESTART_DELAY" ]; then
    RESTART_DELAY=$(( RESTART_DELAY * 2 ))
    if [ "$RESTART_DELAY" -gt "$MAX_RESTART_DELAY" ]; then
      RESTART_DELAY="$MAX_RESTART_DELAY"
    fi
  fi
done
