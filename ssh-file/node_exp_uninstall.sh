#!/bin/bash
# Script to completely uninstall node_exporter
# Usage: sudo bash uninstall_node_exporter.sh

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root using sudo"
    exit 1
fi

echo "===== Node Exporter Uninstaller ====="
echo "Going to remove all Node Exporter-related directories and files from the system"
echo "This will remove services, binaries, and configurations"
echo -n "Continue? (y/n): "
read -r confirmation

if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo "Uninstall canceled"
    exit 0
fi

echo "Starting uninstall process..."

# 1. Stop node_exporter service if running through systemd
if systemctl is-active --quiet node_exporter; then
    echo "Stopping node_exporter systemd service..."
    systemctl stop node_exporter
    systemctl disable node_exporter
    rm -f /etc/systemd/system/node_exporter.service
    systemctl daemon-reload
    echo "Node Exporter service removed"
else
    # Try to kill any node_exporter process
    if pgrep node_exporter > /dev/null; then
        echo "Stopping node_exporter process..."
        pkill -f node_exporter
        sleep 2
    fi
fi

# 2. Function to find and remove Node Exporter directories
remove_node_exporter_dirs() {
    local search_path="$1"
    local dirs
    
    # Find directories matching node_exporter pattern
    dirs=$(find "$search_path" -regextype posix-extended -regex ".*node[_-]exporter[^/]*" 2>/dev/null)
    
    if [ -n "$dirs" ]; then
        echo "Found Node Exporter directories in $search_path:"
        echo "$dirs"
        echo "Removing directories..."
        echo "$dirs" | while read -r dir; do
            rm -rf "$dir"
            echo "Removed: $dir"
        done
    fi
}

# 3. Search and remove Node Exporter directories in common locations
SEARCH_PATHS=(
    "/opt"
    "/usr/local"
    "/usr/local/bin"
    "/var/lib"
    "/etc"
    "/home"
)

for path in "${SEARCH_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "Searching for Node Exporter directories in $path..."
        remove_node_exporter_dirs "$path"
    fi
done

# 4. Remove Node Exporter binary
NODE_EXPORTER_BINARIES=(
    "/usr/local/bin/node_exporter"
    "/usr/bin/node_exporter"
    "/bin/node_exporter"
)

for binary in "${NODE_EXPORTER_BINARIES[@]}"; do
    if [ -f "$binary" ]; then
        echo "Removing binary: $binary"
        rm -f "$binary"
    fi
done

# 5. Remove Node Exporter user and group if they exist
if getent passwd node_exporter >/dev/null; then
    echo "Removing node_exporter user..."
    userdel -r node_exporter 2>/dev/null || true
fi

if getent group node_exporter >/dev/null; then
    echo "Removing node_exporter group..."
    groupdel node_exporter 2>/dev/null || true
fi

# 6. Clean up any temporary or downloaded files
echo "Cleaning up temporary files..."
rm -rf /tmp/node_exporter* 2>/dev/null
rm -rf ${HOME}/node_exporter* 2>/dev/null

# 7. Final cleanup of any remaining processes
pkill -9 -f node_exporter 2>/dev/null || true

# 8. Remove any configuration files
echo "Searching for remaining Node Exporter configuration files..."
find / -type f -name "*node_exporter*.yml" -o -name "*node_exporter*.yaml" -o -name "*node_exporter*.conf" 2>/dev/null | while read -r file; do
    echo "Removing config file: $file"
    rm -f "$file"
done

# 9. Remove textfile collector directory if it exists
if [ -d "/var/lib/node_exporter" ]; then
    echo "Removing textfile collector directory..."
    rm -rf /var/lib/node_exporter
fi

echo "===== Uninstallation Complete ====="
echo "Node Exporter has been completely removed from your system"
