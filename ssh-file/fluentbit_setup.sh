#!/bin/bash

# Set error handling
set -euo pipefail

# Function to handle errors
error_handler() {
    echo "Error occurred in script at line: $1"
    exit 1
}

trap 'error_handler ${LINENO}' ERR

# Function to check if command executed successfully
# check_command() {
#     if [ $? -ne 0 ]; then
#         echo "Error: $1 failed"
#         exit 1
#     fi
# }

# Kill Prometheus process if running
# echo "Killing Prometheus process..."
# pkill prometheus || true  # Don't fail if process doesn't exist

# echo "Removing prometheus packages..."
# sudo rm -rf /home/ubuntu/prometheus-*
# check_command "Prometheus cleanup"

# Install Fluent Bit
echo "Installing Fluent Bit..."
if ! curl -sSf https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh; then
    echo "Error: Failed to install Fluent Bit"
    exit 1
fi

# Update Fluent Bit configuration
echo "Updating Fluent Bit configuration..."

# Validate input
while true; do
    read -p "Enter the log filename (e.g., index, remote-admin): " LOGFILE
    if [[ ! -z "$LOGFILE" ]]; then
        break
    fi
    echo "Logs filename cannot be empty. Please try again."
done

while true; do
    read -p "Enter the environment (e.g., staging, prod): " ENV
    if [[ ! -z "$ENV" ]]; then
        break
    fi
    echo "Environment cannot be empty. Please try again."
done

while true; do
    read -p "Enter the service name (e.g., dilicut-admin, remote): " SVC
    if [[ ! -z "$SVC" ]]; then
        break
    fi
    echo "Service name cannot be empty. Please try again."
done

# Define configuration file path
file_name="/etc/fluent-bit/fluent-bit.conf"

# Ensure directory exists
sudo mkdir -p /etc/fluent-bit

# Create configuration with proper permissions
sudo tee "$file_name" > /dev/null <<EOL
[SERVICE]
    flush                   5
    log_level               info
    daemon                  off
    parsers_file            parsers.conf

[INPUT]
    name                    tail
    tag                     ${LOGFILE}-out_logs
    path                    /home/ubuntu/.pm2/logs/${LOGFILE}-out.log
    refresh_interval        5
    rotate_wait             30
    mem_buf_limit           100MB
    skip_long_lines         On
    parser                  json
    read_from_head          true

[INPUT]
    name                    tail
    tag                     ${LOGFILE}-error_logs
    path                    /home/ubuntu/.pm2/logs/${LOGFILE}-error.log
    refresh_interval        5
    rotate_wait             30
    mem_buf_limit           100MB
    skip_long_lines         On
    parser                  json
    read_from_head          true

[OUTPUT]
    name                    loki
    match                   ${LOGFILE}-out_logs
    host                    150.107.254.232
    port                    3100
    labels                  log=out_logs, service=${SVC}, env=${ENV}
    auto_kubernetes_labels  off

[OUTPUT]
    name                    loki
    match                   ${LOGFILE}-error_logs
    host                    150.107.254.232
    port                    3100
    labels                  log=error_logs, service=${SVC}, env=${ENV}
    auto_kubernetes_labels  off

EOL

# Verify configuration file was created
if [ ! -f "$file_name" ]; then
    echo "Error: Failed to create configuration file"
    exit 1
fi

echo "Configuration file created successfully at $file_name"
echo "Configuration contents:"
cat "$file_name"

sudo systemctl restart fluent-bit.service 
sudo systemctl enable fluent-bit.service
sudo systemctl status fluent-bit.service
echo "It will show output of fluent-bit service, If you want to stop it press Ctrl + C key"
sleep 5
sudo journalctl -u fluent-bit.service -f