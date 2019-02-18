#!/bin/bash

set -e

export SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

source $SCRIPT_DIR/deployment-vars.sh

serverless remove

cd $SCRIPT_DIR/01-ec2
./remove.sh
cd $SCRIPT_DIR

cd $SCRIPT_DIR/00-vpc
./remove.sh
cd $SCRIPT_DIR
