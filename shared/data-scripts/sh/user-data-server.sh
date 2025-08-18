#!/bin/bash
# shellcheck disable=SC2154
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

sudo bash /ops/shared/scripts/install_consul_server.sh "${consul_ent_license}" "${datacenter}"
# shellcheck disable=SC1091
source /home/ubuntu/.bashrc
