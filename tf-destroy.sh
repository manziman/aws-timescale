#!/bin/bash

set -e

terraform destroy \
    -var aws_access_id=$(gpg -d -q ~/.aws/themanzi-access.key) \
    -var aws_secret_id=$(gpg -d -q ~/.aws/themanzi-secret.key)