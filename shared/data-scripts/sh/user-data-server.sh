#!/bin/bash
set -e

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install -y jq

echo "Waiting for /ops/shared/scripts to be available..."
for i in {1..60}; do
  if [ -d /ops/shared/scripts ]; then
    echo "Scripts directory present. Proceeding..."
    break
  fi
  echo "Waiting... ($i/60)"
  sleep 5
done

sudo bash /ops/shared/scripts/install_consul_server.sh "${datacenter}"

source /home/ubuntu/.bashrc
