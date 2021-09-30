resource "google_project_service" "gcp_services" {
  for_each           = toset(var.gcp_service_list)
  project            = var.project_id
  service            = each.key
  disable_dependent_services = true
  disable_on_destroy = true
}

## Very sensitive resource. Problems with restore

//resource "google_endpoints_service" "birds_api" {
//  service_name   = "birds-api.endpoints.${var.project_id}.cloud.goog"
//  project        = var.project_id
//  openapi_config = file("${path.module}/birds_api_spec.yml")
//
//  depends_on = [google_project_service.gcp_services]
//
//  lifecycle {
//      prevent_destroy = true
//  }

//}
