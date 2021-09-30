#!/bin/bash

## Import values from .env file
set -o allexport; source .env; set +o allexport

project=$GCP_PROJECT
ROOT_PATH=$(pwd)

export TF_VAR_project_id=$GCP_PROJECT
export TF_VAR_project_name=$GCP_PROJECT_NAME

## Service account key
SERVICE_ACCOUNT_JSON=keys/${SERVICE_ACCOUNT_NAME}.json

if [ -f "$SERVICE_ACCOUNT_JSON" ]; then
    echo "$SERVICE_ACCOUNT_JSON is aquired."
    ## Set Default GCP service account
    gcloud config set account ${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com

    ###
    echo "Backup firestore..."
    gcloud firestore export gs://firestore-backup-$project > db_backup.txt

    ### DB Clean Up
    export GOOGLE_CLOUD_PROJECT=$project
    export GOOGLE_APPLICATION_CREDENTIALS=$ROOT_PATH/keys/service-account-gcp-app.json
    cd $ROOT_PATH/birdsopedia/web/tools/
    go run cleandb.go

    ### Destroy
    cd $ROOT_PATH/terraform
    ## To be able Terraform use service account
    export GOOGLE_APPLICATION_CREDENTIALS=$ROOT_PATH/keys/service-account-gcp-app.json
    terraform destroy -auto-approve

    BUCKET_NAME=tf-state-$GCP_PROJECT
    gsutil rm -r gs://$BUCKET_NAME

    sleep 10s

    cd $ROOT_PATH/keys
    ### Clean up service-account key file
    rm -rf "$SERVICE_ACCOUNT_NAME.json"

else
 echo "$SERVICE_ACCOUNT_JSON doesnt exist. Nothing to delete with"
fi