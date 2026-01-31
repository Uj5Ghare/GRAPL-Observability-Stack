#!/bin/bash

echo "Removing existing node-exporter" 
pkill node_exporter
sudo rm -rf ${HOME}/node_exporter*

echo "Installing node-exporter" 
cd ${HOME} 
wget https://github.com/prometheus/node_exporter/releases/download/v1.9.0/node_exporter-1.9.0.linux-amd64.tar.gz
tar -xvf node_exporter-1.9.0.linux-amd64.tar.gz
sudo mv node_exporter-1.9.0.linux-amd64/node_exporter /usr/local/bin/ 
sudo rm -rf node_exporter-1.9.0.linux-amd64.tar.gz node_exporter-1.9.0.linux-amd64

echo "Creating systemd service for node-exporter"
sudo tee /etc/systemd/system/node_exporter.service << EOF 
[Unit]
Description=Node Exporter
After=network-online.target

[Service]
User=ubuntu
Group=ubuntu
Type=simple
ExecStart=/usr/local/bin/node_exporter 

[Install]
WantedBy=multi-user.target
EOF

echo "Starting and enabling node-exporter"
sudo systemctl daemon-reload 
sudo systemctl start node_exporter.service
sudo systemctl enable node_exporter.service
sudo systemctl status node_exporter.service