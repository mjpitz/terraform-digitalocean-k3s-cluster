#!/usr/bin/env bash

readonly asset_file=/etc/rancher/k3s/k3s.yaml

echo "waiting for asset ${asset_file}.."

while [[ ! -e ${asset_file} ]]; do
  sleep 1
done
