# module "service_accounts_with_conditiions" {
#   source = "./modules/gcp-service-accounts"
#   project_id = "blah"
#   names = ["sa-iam-condition-tf"]
#   role = "roles/compute.instanceAdmin"
#   condition = {
#     expression = "request.time < timestamp(\"2025-03-30T00:00:00.000Z\")"
#     title = "expire-blah-blah"
#   }
# }



# module "service-accounts" {
#   source  = "terraform-google-modules/service-accounts/google"
#   version = "4.5.3"
#   project_id    = var.gcp_project
# #   prefix        = "test-sa"
# #   names         = ["first", "second"]
#   names         = ["cloudbuild-service-account"]
#   project_roles = [
#     "${var.gcp_project}=>roles/owner",
#     # "${var.gcp_project}=>roles/viewer",
#   ]
# }

# module "service-accounts" {
#   source  = "terraform-google-modules/service-accounts/google"
#   version = "4.5.3"
#   project_id    = var.gcp_project
#   names         = ["compute-service-account"]
#   project_roles = [
#     "${var.gcp_project}=>roles/owner"
#   ]
# }









# Cloudbuild service account

resource "google_service_account" "cloudbuild-service-account" {
  account_id  = "cloudbuild-service-account"
  description = "Service account for cloudbuild"
  project     = var.gcp_project
}

resource "google_project_iam_member" "cloudbuild-sa-project-roles" {
  project = var.gcp_project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.cloudbuild-service-account.email}"
}

# Compute service account

resource "google_service_account" "compute-service-account" {
  account_id  = "compute-service-account"
  description = "Service account for GCE"
  project     = var.gcp_project
}

resource "google_project_iam_member" "compute-sa-project-roles" {
  project = var.gcp_project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.compute-service-account.email}"
}

# keys
# resource "google_service_account_key" "keys" {
#   service_account_id = google_service_account.compute-service-account.email
# }
