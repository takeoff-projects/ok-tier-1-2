variable "project_id" {
  type = string
}

variable "collection_name" {
  type    = string
  default = "bird"
}

variable "firestore_zone" {
  type    = string
  default = "us-central1"
}
