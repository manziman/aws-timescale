#!/bin/bash

set -e

terraform apply \
    -var aws_access_id=$(gpg -d -q ~/.aws/themanzi-serverless-access.key) \
    -var aws_secret_id=$(gpg -d -q ~/.aws/themanzi-serverless-secret.key)