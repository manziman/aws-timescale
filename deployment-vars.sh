#!/bin/bash

export SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

export POSTGRES_PASS=$(cat $SCRIPT_DIR/test_postgress_pass.txt)
export AWS_PROFILE="themanzi"
export REGION=us-east-1
export AWS_REGION=$REGION