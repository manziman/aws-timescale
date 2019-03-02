#!/bin/bash

set -e

export REGION=us-east-1
export SCRIPT_DIR="$( cd "$(dirname "$0")" ; pwd -P )"
export DB_INTERNAL_HOSTNAME=$(cat $SCRIPT_DIR/terraform.tfstate | jq -r .modules[0].outputs.db_internal_hostname.value)
export DB_SECURITY_GROUP=$(cat $SCRIPT_DIR/terraform.tfstate | jq -r .modules[0].outputs.db_security_group_id.value)
export DB_SUBNET=$(cat $SCRIPT_DIR/terraform.tfstate | jq -r .modules[0].outputs.db_subnet_id.value)
export POSTGRES_PASS='p@ssw0rd'

AWS_ACCESS_KEY_ID=$(gpg -d -q ~/.aws/demo-creds-id.gpg) \
    AWS_SECRET_ACCESS_KEY=$(gpg -d -q ~/.aws/demo-creds-secret.gpg) \
    serverless remove
