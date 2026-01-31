#!/bin/bash
# Script to completely uninstall Prometheus
# Usage: sudo bash uninstall_prometheus.sh

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root using sudo"
    exit 1
fi

echo "===== Prometheus Uninstaller ====="
echo "Going to remove all Prometheus-related directories and files from the system"
echo "This will remove services, data, configs, and logs"
echo -n "Continue? (y/n): "
read -r confirmation

if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo "Uninstall canceled"
    exit 0
fi

echo "Starting uninstall process..."

# 1. Stop Prometheus service if running through systemd
if systemctl is-active --quiet prometheus; then
    echo "Stopping Prometheus systemd service..."
    systemctl stop prometheus
    systemctl disable prometheus
    rm -f /etc/systemd/system/prometheus.service
    systemctl daemon-reload
    echo "Prometheus service removed"
else
    # Try to kill any Prometheus process
    if pgrep prometheus > /dev/null; then
        echo "Stopping Prometheus process..."
        pkill -f prometheus
        sleep 2
    fi
fi

# 2. Function to find and remove Prometheus directories
remove_prometheus_dirs() {
    local search_path="$1"
    local dirs
    
    # Find directories matching prometheus pattern
    dirs=$(find "$search_path" -regextype posix-extended -regex ".*prometheus[^/]*" 2>/dev/null)
    
    if [ -n "$dirs" ]; then
        echo "Found Prometheus directories in $search_path:"
        echo "$dirs"
        echo "Removing directories..."
        echo "$dirs" | while read -r dir; do
            rm -rf "$dir"
            echo "Removed: $dir"
        done
    fi
}

# 3. Search and remove Prometheus directories in common locations
SEARCH_PATHS=(
    "/opt"
    "/usr/local"
    "/var/lib"
    "/var/log"
    "/etc"
    "/home"
)

for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "Searching for Prometheus directories in $path..."
        remove_prometheus_dirs "$path"
    fi
done

# 4. Remove specific Prometheus binaries
PROMETHEUS_BINARIES=(
    "/usr/local/bin/prometheus"
    "/usr/local/bin/promtool"
)

for binary in "${PROMETHEUS_BINARIES[@]}"; do
    if [ -f "$binary" ]; then
        echo "Removing binary: $binary"
        rm -f "$binary"
    fi
done

# 5. Remove Prometheus user and group if they exist
if getent passwd prometheus >/dev/null; then
    echo "Removing prometheus user..."
    userdel -r prometheus 2>/dev/null || true
fi

if getent group prometheus >/dev/null; then
    echo "Removing prometheus group..."
    groupdel prometheus 2>/dev/null || true
fi

# 6. Final cleanup of any remaining processes
pkill -9 -f prometheus 2>/dev/null || true

# 7. Find and remove any remaining prometheus configuration files
echo "Searching for remaining Prometheus configuration files..."
find / -type f -name "*prometheus*.yml" -o -name "*prometheus*.yaml" -o -name "*prometheus*.conf" 2>/dev/null | while read -r file; do
    echo "Removing config file: $file"
    rm -f "$file"
done

echo "===== Uninstallation Complete ====="
echo "Prometheus has been completely removed from your system"
