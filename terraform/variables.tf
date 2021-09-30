
variable "project_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "provider_region" {
  type    = string
  default = "us-central1"
}

variable "regions" {
  type = list(string)
}

variable "bird_collection_name" {
  type = string
}
