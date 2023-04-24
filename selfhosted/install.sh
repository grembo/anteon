#!/bin/bash

set -e

echo "⚡ Installing Ddosify Self Hosted..."

echo "🔍 Checking prerequisites..."

# Check if Git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "❌ Git not found. Please install Git and try again."
  exit 1
fi

# Check if Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker not found. Please install Docker and try again."
  exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  echo "❌ Docker Compose not found. Please install Docker Compose and try again."
  exit 1
fi


echo "🚀 Starting installation of Ddosify Self Hosted..."

REPO_DIR="$HOME/.ddosify"

# Check if repository already exists
if [ -d "$REPO_DIR" ]; then
  echo "🔄 Repository already exists at $REPO_DIR - Attempting to update..."
  cd "$REPO_DIR"
  git checkout selfhosted_release >/dev/null 2>&1
  cd "$REPO_DIR/selfhosted"
  git pull >/dev/null 2>&1

  # Check for errors during pull
  if [ $? -ne 0 ]; then
    read -p "⚠️ Error updating repository. Clean and update? [Y/n]: " answer
    answer=${answer:-Y}
    if [[ $answer =~ ^[Yy]$ ]]; then
      git reset --hard >/dev/null 2>&1
      git clean -fd >/dev/null 2>&1
      git pull >/dev/null 2>&1
    fi
  fi
else
  # Clone the repository
  echo "📦 Cloning repository to $REPO_DIR directory..."
  git clone https://github.com/ddosify/ddosify.git "$REPO_DIR" >/dev/null 2>&1
  cd "$REPO_DIR"
  git checkout selfhosted_release >/dev/null 2>&1
  cd "$REPO_DIR/selfhosted"
fi

# Determine which compose command to use
COMPOSE_COMMAND="docker-compose"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  COMPOSE_COMMAND="docker compose"
fi

echo "🚀 Deploying Ddosify Self Hosted..."
$COMPOSE_COMMAND -f "$REPO_DIR/selfhosted/docker-compose.yml" up -d
echo "⏳ Waiting for services to be ready..."
docker run --rm --network selfhosted_ddosify busybox:1.34.1 /bin/sh -c "until nc -z nginx 80 && nc -z backend 8008 && nc -z hammermanager 8001 && nc -z rabbitmq_celery 5672 && nc -z rabbitmq_job 5672 && nc -z postgres_selfhosted 5432 && nc -z influxdb 8086; do sleep 5; done"
echo "✅ Ddosify Self Hosted installation complete!"
echo "📁 Installation directory: $REPO_DIR/selfhosted"

echo "🌐 Open http://localhost:8014 in your browser to access the application."
