terraform {
  backend "gcs" {
    prefix = "terraform-state"
  }
}

########################## The basics ################################
provider "google" {
  project = var.project_id
  region = var.provider_region
}

provider "google-beta" {
  project = var.project_id
  region = var.provider_region
}

##### Custom stuff ######
module "google_apis" {
  source = "./modules/gcp_apis"
  project_id = var.project_id
}

module "firestore" {
  source = "./modules/firestore"
  depends_on = [
    module.google_apis
  ]
  project_id = var.project_id
  collection_name = var.bird_collection_name
  firestore_zone = "us-central1"
}

module "cloud_run" {
  source = "./modules/cloud_run"
  depends_on = [
    module.google_apis
  ]
  project_id = var.project_id
}

module "container_registry" {
  source = "./modules/container_registry"
  project_id = var.project_id
}

module "cloud_endpoints" {
  source = "./modules/cloud_endpoints"
  project_id = var.project_id
  depends_on = [
    module.cloud_run
  ]
}