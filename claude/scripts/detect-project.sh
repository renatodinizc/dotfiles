#!/bin/bash
# SessionStart hook: detect project type and inject context for Claude.
# Output goes directly into Claude's session context.

# Rust project detection
if [ -f "Cargo.toml" ]; then
  echo "## Project Context"
  echo "Rust project detected."

  # Scan key dependencies from Cargo.toml (and workspace members)
  CARGO_FILES="Cargo.toml"
  if [ -f "Cargo.lock" ]; then
    # Also check workspace member Cargo.toml files
    CARGO_FILES=$(find . -maxdepth 3 -name "Cargo.toml" 2>/dev/null | tr '\n' ' ')
  fi

  DEPS=""
  for f in $CARGO_FILES; do
    [ -f "$f" ] || continue
    grep -q 'tokio' "$f" 2>/dev/null && DEPS="$DEPS tokio"
    grep -q 'rdkafka\|kafka' "$f" 2>/dev/null && DEPS="$DEPS kafka"
    grep -q 'actix' "$f" 2>/dev/null && DEPS="$DEPS actix-web"
    grep -q 'axum' "$f" 2>/dev/null && DEPS="$DEPS axum"
    grep -q 'tonic\|prost' "$f" 2>/dev/null && DEPS="$DEPS gRPC"
    grep -q 'sqlx\|diesel\|sea-orm' "$f" 2>/dev/null && DEPS="$DEPS SQL"
    grep -q 'clickhouse' "$f" 2>/dev/null && DEPS="$DEPS ClickHouse"
    grep -q 'redis' "$f" 2>/dev/null && DEPS="$DEPS Redis"
    grep -q 'nats' "$f" 2>/dev/null && DEPS="$DEPS NATS"
    grep -q 'lapin\|amqp' "$f" 2>/dev/null && DEPS="$DEPS RabbitMQ"
    grep -q 'tower' "$f" 2>/dev/null && DEPS="$DEPS tower"
    grep -q 'tracing' "$f" 2>/dev/null && DEPS="$DEPS tracing"
  done

  # Deduplicate
  if [ -n "$DEPS" ]; then
    DEPS=$(echo "$DEPS" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    echo "Key deps: $DEPS"
  fi

  # Multi-service detection
  if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    echo "Multi-service project (docker-compose found)."
  fi
fi
