#!/bin/bash

## Import values from .env file
set -o allexport; source .env; set +o allexport

project=$GCP_PROJECT


## Service account key
SERVICE_ACCOUNT_JSON=keys/${SERVICE_ACCOUNT_NAME}.json


if [ -f "$SERVICE_ACCOUNT_JSON" ]; then
    echo "$SERVICE_ACCOUNT_JSON exists."
else
  echo "You need create $SERVICE_ACCOUNT_JSON ..."
fi

## Set Default GCP service account
gcloud config set account ${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com

gcloud auth list

echo "Building Web-App"
##Build docker image for go-birds, push to Docker registry
gcloud builds submit --tag=gcr.io/roi-takeoff-user61/go-birds:latest ./birdsopedia/web/

echo "Deploy Web-App"
## Deploy updated version from image
gcloud run deploy go-birds --image=gcr.io/roi-takeoff-user61/go-birds:latest --platform="managed" --region "us-central1"

echo "Building Api"
##Build docker image for go-birds-api, push to Docker registry
gcloud builds submit --tag=gcr.io/roi-takeoff-user61/go-birds-api:latest ./birdsopedia/api/

echo "Deploy Api"
## Deploy updated version from image
gcloud run deploy go-birds-api --image=gcr.io/roi-takeoff-user61/go-birds-api:latest --platform="managed" --region "us-central1"