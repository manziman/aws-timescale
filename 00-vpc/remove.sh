#!/bin/bash

export VPC_SUBNET='10.0.0.0/16'
export DB_SUBNET_PUB='10.0.1.0/24'
export DB_SUBNET_PRIV='10.0.2.0/24'

serverless remove