#!/bin/bash

## Import values from .env file
set -o allexport; source .env; set +o allexport

ROOT_PATH=$(pwd)

cd $ROOT_PATH

project=$GCP_PROJECT
ENDPOINTS_SERVICE_NAME=birds-api.endpoints.roi-takeoff-user61.cloud.goog
CLOUD_RUN_HOSTNAME=birds-api.endpoints.roi-takeoff-user61.cloud.goog
CLOUD_RUN_SERVICE_URL=https://api-gateway-47fkf6rhuq-uc.a.run.app


### Deploy Endpoint  specification with Open-API config, grab config version into variable
cd $ROOT_PATH/terraform/modules/cloud_endpoints
gcloud endpoints services deploy birds_api_spec.yml --project $project
config=$(gcloud endpoints configs list --service=$ENDPOINTS_SERVICE_NAME --limit=1 | head -2 | tail -1|cut -d' ' -f1)
echo "Obtained config $config"

## Enable Cloud Endpoint created by Terraform
gcloud services enable $ENDPOINTS_SERVICE_NAME

##Building a new ESPv2 image API_GATEWAY from
#https://cloud.google.com/endpoints/docs/openapi/get-started-cloud-run#configure_esp
cd $ROOT_PATH
chmod +x gcloud_build_image.sh

./gcloud_build_image.sh -s $CLOUD_RUN_HOSTNAME -c $config -p $project

gcloud run deploy api-gateway \
  --image="gcr.io/$project/endpoints-runtime-serverless:2.30.3-$ENDPOINTS_SERVICE_NAME-$config" \
  --allow-unauthenticated \
  --platform managed \
  --region=us-central1\
  --project=$project
