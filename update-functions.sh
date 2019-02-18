#!/bin/bash

set -e

export SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

source $SCRIPT_DIR/deployment-vars.sh

serverless deploy