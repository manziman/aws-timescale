#!/bin/bash

set -e

export SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

source $SCRIPT_DIR/deployment-vars.sh

cd $SCRIPT_DIR/00-vpc
./deploy.sh
cd $SCRIPT_DIR

cd $SCRIPT_DIR/01-ec2
./deploy.sh
cd $SCRIPT_DIR

serverless deploy