#!/bin/bash

# update-arma-server.sh - Script to update Arma server configuration
# Usage: ./update-arma-server.sh [--no-restart]

REPO_DIR="/home/mikeb/arma-server-config"
SERVICE_NAME="arma-reforger"
ARMA_CONFIG_DIR="/home/mikeb/arma/config"
RESTART=true
REPO_URL="https://github.com/FlunkyMonkey/arma-server.git"

# Process command line arguments
for arg in "$@"; do
  if [ "$arg" == "--no-restart" ]; then
    RESTART=false
  fi
done

# Print header
echo "==============================================="
echo "Arma Reforger Server Configuration Update Script"
echo "==============================================="
echo "Starting update process at $(date)"
echo

# Pull latest changes from repository
echo "Pulling latest changes from GitHub repository..."
cd "$REPO_DIR"
git pull

if [ $? -ne 0 ]; then
  echo "Error: Failed to pull changes from repository"
  exit 1
fi

echo "Repository updated successfully!"

# Copy systemd service file if it exists in the repo
if [ -f "$REPO_DIR/$SERVICE_NAME.service" ]; then
  echo "Updating systemd service file..."
  sudo cp "$REPO_DIR/$SERVICE_NAME.service" "/etc/systemd/system/"
  sudo systemctl daemon-reload
  echo "Systemd service file updated"
fi

# Copy configuration files
echo "Updating Arma server configuration files..."
# Ensure the destination directory exists
mkdir -p "$ARMA_CONFIG_DIR"

# Copy config.json if it exists
if [ -f "$REPO_DIR/config.json" ]; then
  cp "$REPO_DIR/config.json" "$ARMA_CONFIG_DIR/"
  echo "Configuration file config.json updated"
else
  echo "Warning: config.json not found in repository"
fi

# Copy any other configuration files
for config_file in "$REPO_DIR"/*.json "$REPO_DIR"/*.cfg "$REPO_DIR"/*.ini; do
  if [ -f "$config_file" ] && [ "$(basename "$config_file")" != "config.json" ]; then
    cp "$config_file" "$ARMA_CONFIG_DIR/"
    echo "Copied additional config file: $(basename "$config_file")"
  fi
done

# Restart service if not disabled
if [ "$RESTART" = true ]; then
  echo "Restarting Arma Reforger server service..."
  sudo systemctl restart $SERVICE_NAME
  
  # Check if service started successfully
  sleep 5
  if systemctl is-active --quiet $SERVICE_NAME; then
    echo "Arma Reforger server service restarted successfully!"
  else
    echo "Warning: Arma Reforger server service failed to restart properly"
    echo "Check status with: sudo systemctl status $SERVICE_NAME"
  fi
else
  echo "Service restart skipped (--no-restart option used)"
  echo "You may need to restart the service manually with:"
  echo "sudo systemctl restart $SERVICE_NAME"
fi

echo
echo "Update completed at $(date)"
echo "==============================================="
