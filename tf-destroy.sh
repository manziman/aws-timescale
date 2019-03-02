#!/bin/bash

set -e

terraform destroy \
    -var aws_access_id=$(gpg -d -q ~/.aws/demo-creds-id.gpg) \
    -var aws_secret_id=$(gpg -d -q ~/.aws/demo-creds-secret.gpg) \
    webhooks-tf.plan