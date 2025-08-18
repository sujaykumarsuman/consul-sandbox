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

# Install payload
# ---------------
# Set consul payload id in .bashrc
echo "export PAYLOAD_ID=${payload_id}" | sudo tee -a /home/ubuntu/.bashrc > /dev/null
sudo bash /ops/shared/scripts/install/${payload_binary}.sh "${payload_id}"

# Install consul client
# ---------------------


# source .bashrc to load environment variables
source /home/ubuntu/.bashrc
