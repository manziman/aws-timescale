# TimestreamDB Webhook Consumer Example (Using Serverless Framework for deployment)

## Setup

Install Serverless framework:

```
$ npm i -g serverless
```

Install dependencies:
```
$ npm i
```

## Deploying/Updating full stack

Ensure that you have aws credentials set in your default profile (with proper permissions).

Run main deployment script:
```
$ ./deploy-main.sh
```

## Updating functions only

Run:
```
$ ./update-functions.sh
```

## Tearing down

Run teardown script:
```
$ ./remove-main.sh
```