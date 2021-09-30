resource "google_project_service" "gcp_services" {
  for_each           = toset(var.gcp_service_list)
  project            = var.project_id
  service            = each.key
  disable_dependent_services = true
  disable_on_destroy = true
}

resource "google_cloud_run_service" "default" {
  name     = "go-birds"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/roi-takeoff-user61/go-birds:latest"
      }
    }
  }
  depends_on = [google_project_service.gcp_services]
}

resource "google_cloud_run_service" "go-birds-api" {
  name     = "go-birds-api"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/roi-takeoff-user61/go-birds-api:latest"
      }
    }
  }
  depends_on = [google_project_service.gcp_services]
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
  depends_on = [google_project_service.gcp_services]
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.default.location
  project     = google_cloud_run_service.default.project
  service     = google_cloud_run_service.default.name

  policy_data = data.google_iam_policy.noauth.policy_data

  depends_on = [google_project_service.gcp_services]
}

resource "google_cloud_run_service_iam_policy" "noauth-api" {
  location    = google_cloud_run_service.go-birds-api.location
  project     = google_cloud_run_service.go-birds-api.project
  service     = google_cloud_run_service.go-birds-api.name

  policy_data = data.google_iam_policy.noauth.policy_data

  depends_on = [google_project_service.gcp_services]
}