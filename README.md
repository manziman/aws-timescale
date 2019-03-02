# TimestreamDB Webhook Consumer Example (Using Serverless Framework for deployment)

## Setup

Install Serverless framework:

```
$ npm i -g serverless
```

Install and Init Terraform:

```
$ curl https://releases.hashicorp.com/terraform/<tf_version>/terraform_<tf_version>_<os>_<arch>.zip > terraform.zip
$ unzip -d /usr/local/bin/
$ terraform init
```

Install dependencies:
```
$ npm i
```

## Creating Terraform plan for deployment

```
$ make plan
```

## Apply Terraform plan and deploy/update Serverless functions

```
$ make deploy
```

## Destroy stack

```
$ make destroy
```