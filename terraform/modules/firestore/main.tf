###
### https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application

#Note
# App Engine applications cannot be deleted once they're created;
# you have to delete the entire project to delete the application.
# Terraform will report the application has been successfully deleted;
# this is a limitation of Terraform, and will go away in the future. Terraform is not able to delete App Engine applications.

//resource "google_app_engine_application" "app" {
//  project       = var.project_id
//  location_id   = "us-central"
//  database_type = "CLOUD_FIRESTORE"
//}

resource "google_firestore_index" "indx-bird" {
  project = var.project_id

  collection = var.collection_name

  fields {
    field_path = "species"
    order = "ASCENDING"
  }

  fields {
    field_path = "description"
    order = "DESCENDING"
  }

  fields {
    field_path = "id"
    order = "DESCENDING"
  }
}

resource "google_firestore_document" "bird-sample" {
  project     = var.project_id
  collection  = var.collection_name
  document_id = "bird-sample"
  fields      = "{\"id\":{\"stringValue\":\"bird-sample\"},\"species\":{\"stringValue\":\"pigeon\"},\"description\":{\"stringValue\":\"Common in cities\"}}"

}