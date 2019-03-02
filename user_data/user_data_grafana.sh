#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -yq && apt-get upgrade -yq
apt-get install openssh-server -yq
service ssh start
echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
curl https://packages.grafana.com/gpg.key | apt-key add -
apt-get update -yq
apt-get install grafana -yq
systemctl daemon-reload
systemctl start grafana-server
systemctl enable grafana-server.service
