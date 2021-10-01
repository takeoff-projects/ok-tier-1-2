# Birdsopedia application

## Prerequisites

1. Install [Brew](https://brew.sh/)
2. Update GCP project meta-data into `.env`
3. Python 3.8 or `brew install python@3.8`
4. [Gcloud SDK](https://cloud.google.com/sdk/docs/quickstart-maco)
5. [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
6. GoLang or `brew install go`

## Install/Deploy

Run `./start_my_app.sh`

## Stop/Destroy

Run `./stop_my_app.sh`

## Links
* [Go-birds-Web](https://go-birds-47fkf6rhuq-uc.a.run.app) Golang docker image + Cloud Run
* [Go-birds-Api](https://go-birds-api-47fkf6rhuq-uc.a.run.app) Golang docker image + Cloud Run
* [Go-birds-Api-Gateway](https://api-gateway-47fkf6rhuq-uc.a.run.app) ESPv2 docker image + Cloud Run + Cloud Endpoint

## API usage

[API contract](https://go-birds-api-47fkf6rhuq-uc.a.run.app/swaggerui/)

## Usage example

Update existing Bird entity:

```
curl --location --request PUT 'https://api-gateway-47fkf6rhuq-uc.a.run.app/birds/500e8289-ad7b-4c39-97a6-439abaac69e9' \
--header 'Content-Type: text/plain' \
--data-raw '{"description": "Very kind", "species":"parrot"}'
```

### Known issues
- IAM Changes to buckets are eventually consistent and may take upto a few minutes to take effect for buckets https://www.terraform.io/docs/language/settings/backends/gcs.html.
- Apiengine could be created  only once per project, without chance to delete/add by Terraform. https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application              
``` App Engine applications cannot be deleted once they're created; you have to delete the entire project to delete the application.
Terraform will report the application has been successfully deleted; this is a limitation of Terraform, and will go away in the future. Terraform is not able to delete App Engine applications.
```
- Firestore creation via Terraform.
- Cloud endpoints deletion by Terraform, required manually restore via gcloud command.

### Further improvements
- CI/CD process triggered by github activities instead of.sh scripts.
- CORS support in Swagger with Try It.
- Using Apigee as Api-Gateway.
- Secure Cloud Runs - Precise IAM policies and Service accounts.