variable "project_id" {
  type = string
}


variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type = list(string)
  default = [
    "run.googleapis.com",
  ]
}
