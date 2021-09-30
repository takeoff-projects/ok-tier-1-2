#!/bin/bash

## Import values from .env file
set -o allexport; source .env; set +o allexport

project=$GCP_PROJECT
## Service account key
SERVICE_ACCOUNT_JSON=keys/${SERVICE_ACCOUNT_NAME}.json
ROOT_PATH=$(pwd)


if [ -f "$SERVICE_ACCOUNT_JSON" ]; then
    echo "$SERVICE_ACCOUNT_JSON file exists."
else
  echo "Creating $SERVICE_ACCOUNT_JSON ..."
  ## Login into GCP
  gcloud auth login $GCP_USER

  ## Set Project
  gcloud config set project $project

  ## Clean garbage entry if exist.
  gcloud iam service-accounts delete ${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com --quiet

  ## Create service account
  gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
    --description="Main service account" \
    --display-name="Service account"

  ## Bind roles
   gcloud projects add-iam-policy-binding ${project} \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

  gcloud projects add-iam-policy-binding ${project} \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"

  gcloud projects add-iam-policy-binding ${project} \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com" \
    --role="roles/owner"

  ## Uncomment for [DEBUG]

#  echo "[] Roles assigned: []"
#  gcloud projects get-iam-policy $project \
#    --flatten="bindings[].members" \
#    --format='table(bindings.role)' \
#    --filter="bindings.members:${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com"

  ## download a key file containing your credentials
   gcloud iam service-accounts keys create $SERVICE_ACCOUNT_JSON\
    --iam-account ${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com

  ## Apply service account for Terraform
  gcloud auth activate-service-account ${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com --key-file=$SERVICE_ACCOUNT_JSON --project=$project

  echo "$SERVICE_ACCOUNT_JSON was created"

fi

## Set Default GCP service account
gcloud config set account ${SERVICE_ACCOUNT_NAME}@${project}.iam.gserviceaccount.com

gcloud auth list

#gcloud auth application-default login

## To be able Terraform use service account
export GOOGLE_APPLICATION_CREDENTIALS=../keys/service-account-gcp-app.json

## Bucket to store Terraform state (skipped if existed)
BUCKET_NAME=tf-state-$GCP_PROJECT
gsutil mb gs://$BUCKET_NAME

## Bucket to store Fitestore backups (skipped if existed)
gsutil mb gs://firestore-backup-$project

## [Optional] Create App Engine if it's not creted
#gcloud app create --region "us-central"

##https://www.terraform.io/docs/language/settings/backends/gcs.html
# IAM Changes to buckets are eventually consistent and may take upto a few minutes to take effect.
# Terraform will return 403 errors till it is eventually consistent.
echo "->>>>>>>Sleeping for 3 minutes for newly  IAM service-account roll-out <<<<<<<<---"
for i in `seq 180 -1 1` ; do echo -ne "\r$i " ; sleep 1 ; done

export TF_VAR_project_id=$GCP_PROJECT
export TF_VAR_project_name=$GCP_PROJECT_NAME

### Terraform INIT
cd $ROOT_PATH/terraform
terraform init \
-backend-config="bucket=$BUCKET_NAME"

### Terraform Validate
terraform validate

### Terraform Plan
terraform plan

## Enables Dockerregistry using Terraform.
terraform apply -target="module.container_registry" -auto-approve

##Build Web-App docker image, push to Docker registry
cd $ROOT_PATH/birdsopedia/web && \
docker build -t gcr.io/$project/go-birds:latest -f Dockerfile . && \
docker push gcr.io/$project/go-birds:latest

##Build Web-API docker image, push to Docker registry
cd $ROOT_PATH/birdsopedia/api && \
docker build -t gcr.io/$project/go-birds-api:latest -f Dockerfile . && \
docker push gcr.io/$project/go-birds-api:latest

cd $ROOT_PATH/terraform

### Terraform Apply all resources and APIS
terraform apply -auto-approve

### Restore Firebase state if existed
cd $ROOT_PATH
backupurl=$(grep 'outputUriPrefix:'  db_backup.txt | cut -d':' -f2-)
dbbackup=db_backup.txt
 if [[ -f "$dbbackup" ]]; then
    echo "$dbbackup exists. Restoring Firestore state"
    echo "Firestore backup: $backupurl"
    gcloud firestore import ${backupurl}
fi

## Restore cloud endpoint -> dangerous to use Terraform
#gcloud endpoints services undelete birds-api.endpoints.roi-takeoff-user61.cloud.goog

###Deploy API_GATEWAY
cd $ROOT_PATH
./deploy_api_gateway.sh