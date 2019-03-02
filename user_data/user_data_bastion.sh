#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -yq && apt-get upgrade -yq
apt-get install openssh-server -yq
service ssh start