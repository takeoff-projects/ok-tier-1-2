variable "project_id" {
  type = string
  default = "roi-takeoff-user61"
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type = list(string)
  default = [
    "containerregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]
}