#!/usr/bin/env bash
export INSTALL_K3S_VERSION="${ version }"
export INSTALL_K3S_SYSTEMD_DIR="/etc/systemd/system"
export INSTALL_K3S_EXEC="${ role }"

curl -sfL https://get.k3s.io | sh -
