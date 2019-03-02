#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -yq && apt-get upgrade -yq
apt-get install openssh-server -yq
service ssh start
echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
curl https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install grafana
systemctl daemon-reload
systemctl start grafana-server
systemctl status grafana-server
systemctl enable grafana-server.service
