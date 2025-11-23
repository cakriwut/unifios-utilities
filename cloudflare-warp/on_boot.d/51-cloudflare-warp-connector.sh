#!/bin/bash

# this should be the connector token from Cloudflare Zero Trust
CONNECTOR_TOKEN="YOUR_CONNECTOR_TOKEN_GOES_HERE"

# ensure this directory exists
mkdir -p /usr/share/keyrings
chmod 0755 /usr/share/keyrings

# setup cloudflare warp repository and GPG key
if [ ! -f /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg ] ; then
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
fi

if [ ! -f /etc/apt/sources.list.d/cloudflare-client.list ] ; then
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
fi

dpkg -l | grep cloudflare-warp 1>/dev/null 2>&1
PACKAGE_INSTALLED=$?

apt update
if [ ${PACKAGE_INSTALLED} != 0 ] ; then
  # attempt to install
  apt install -y cloudflare-warp || exit 1
else
  # attempt to upgrade
  apt upgrade -y cloudflare-warp
fi

# enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# ensure IP forwarding persists across reboots
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

# stop any existing warp-svc service
systemctl stop warp-svc.service 2>/dev/null || true

# start warp-svc daemon service
systemctl enable warp-svc.service
systemctl start warp-svc.service

# wait for warp-svc daemon to initialize before running warp-cli commands
sleep 5

# configure connector if token is provided and not already configured
if [ "${CONNECTOR_TOKEN}" != "YOUR_CONNECTOR_TOKEN_GOES_HERE" ]; then
  # check if already connected
  if ! warp-cli status 2>&1 | grep -q "Connected"; then
    # register connector with token
    warp-cli connector new "${CONNECTOR_TOKEN}" || echo "Warning: connector registration may have failed or already exists"
    
    # connect to Cloudflare WARP
    warp-cli connect || echo "Warning: connection attempt may have failed"
  else
    echo "WARP connector is already connected"
  fi
else
  echo "WARNING: CONNECTOR_TOKEN not configured. Please set the token in the script."
  echo "You can manually configure it later by running:"
  echo "  warp-cli connector new YOUR_TOKEN"
  echo "  warp-cli connect"
fi

# EOF
