#!/bin/bash

set -e

terraform plan \
    -var aws_access_id=$(gpg -d -q ~/.aws/demo-creds-id.gpg) \
    -var aws_secret_id=$(gpg -d -q ~/.aws/demo-creds-secret.gpg) \
    -out webhooks-tf.plan