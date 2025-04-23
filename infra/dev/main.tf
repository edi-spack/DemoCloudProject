# # # Bucket to store website
# # resource "google_storage_bucket" "website" {
# #   # provider = google
# #   name     = "demo-bucket-website-anfduniquefdjfg"
# #   location = "EU"
#
# # }
#
# # # Make new objects public
# # resource "google_storage_object_access_control" "public_rule" {
# #   object = google_storage_bucket_object.static_site_src.name
# #   bucket = google_storage_bucket.website.name
# #   role   = "READER"
# #   entity = "allUsers"
# # }
#
# # # Upload html file to the bucket
# # resource "google_storage_bucket_object" "static_site_src" {
# #   name   = "index.html"
# #   source = "../website/index.html"
# #   bucket = google_storage_bucket.website.name
# #
# # }
#
# # Reserve a static external IP address
# resource "google_compute_global_address" "backend-dev-lb-ip" {
#   name = "backend-dev-lb-ip"
# }
#
# # Get the managed DNS zone
# data "google_dns_managed_zone" "dns_zone" {
#   name = "gcpdns"
# }
#
# # Add the IP to the DNS
# resource "google_dns_record_set" "backend-dev-dns-record" {
#   name         = "dev.${data.google_dns_managed_zone.dns_zone.dns_name}"
#   type         = "A"
#   ttl          = 300
#   managed_zone = data.google_dns_managed_zone.dns_zone.name
#   rrdatas      = [google_compute_global_address.backend-dev-lb-ip.address]
# }
#
# # # Add the bucket as a CDN backend
# # resource "google_compute_backend_bucket" "website-backend" {
# #   name        = "website-backend"
# #   bucket_name = google_storage_bucket.website.name
# #   description = "Contains files needed for the backend"
# #   enable_cdn  = true
# # }
#
# # Add the bucket as a CDN backend
# resource "google_compute_backend_service" "gce-backend-dev" {
#   # name        = module.compute_managed_instance_group.instance_group
#   # enable_cdn  = false
#
#
#
#
#
#
#
#
#
#
#   name                  = "backend-dev"
#   provider              = google-beta
#   protocol              = "HTTP"
#   port_name             = "80"
#   load_balancing_scheme = "INTERNAL_MANAGED" # ???????
#   timeout_sec           = 10
#   enable_cdn            = false
#   # custom_request_headers  = ["X-Client-Geo-Location: {client_region_subdivision}, {client_city}"]
#   # custom_response_headers = ["X-Cache-Hit: {cdn_cache_status}"]
#   # health_checks           = [google_compute_health_check.default.id]
#   backend {
#     # group           = google_compute_instance_group_manager.default.instance_group
#     group           = module.compute_managed_instance_group.self_link
#     balancing_mode  = "UTILIZATION"
#     capacity_scaler = 1.0
#   }
# }
#
# # GCP URL MAP
# resource "google_compute_url_map" "backend-dev-url-map" {
#   name            = "backend-dev-url-map"
#   default_service = google_compute_backend_service.gce-backend-dev.self_link
#   host_rule {
#     hosts        = ["*"]
#     path_matcher = "allpaths"
#   }
#   path_matcher {
#     name            = "allpaths"
#     default_service = google_compute_backend_service.gce-backend-dev.self_link
#   }
# }
#
# # GCP HTTP Proxy (LB)
# resource "google_compute_target_http_proxy" "backend-dev-lb-proxy" {
#   name    = "backend-dev-lb-proxy"
#   url_map = google_compute_url_map.backend-dev-url-map.self_link
# }
#
# # GCP forwarding rule
# resource "google_compute_global_forwarding_rule" "backend-dev-forwarding-rule" {
#   name                  = "backend-dev-forwarding-rule"
#   load_balancing_scheme = "EXTERNAL"
#   ip_address            = google_compute_global_address.backend-dev-lb-ip.address
#   ip_protocol           = "TCP"
#   port_range            = "80"
#   target                = google_compute_target_http_proxy.backend-dev-lb-proxy.self_link
# }
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
# module "compute_instance_template" {
#   source  = "terraform-google-modules/vm/google//modules/instance_template"
#   version = "~> 13.0"
#
#   project_id = var.gcp_project
#   region     = var.gcp_region
#   network    = "default"
#   # subnetwork         = var.subnetwork
#   service_account = google_service_account.compute-service-account.email
#   # subnetwork_project = var.project_id
# }
#
# module "compute_managed_instance_group" {
#   source  = "terraform-google-modules/vm/google//modules/mig"
#   version = "~> 13.0"
#
#   project_id        = var.gcp_project
#   region            = var.gcp_region
#   target_size       = 1
#   hostname          = "backend-mig"
#   instance_template = module.compute_instance_template.self_link
# }

resource "google_cloudbuild_trigger" "develop-push-trigger" {
  name = "develop-push-trigger"
  # location = "global"
  location = "europe-central2"

  github {
    owner = "edi-spack"
    name  = "DemoCloudProject"

    push {
      branch = "develop"
    }
  }

  filename = "cloudbuild.yaml"

  service_account = google_service_account.cloudbuild-service-account.id

  build {
    options {
      default_logs_bucket_behavior = "REGIONAL_USER_OWNED_BUCKET"
    }

    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = ["echo", "This step is only required so default_logs_bucket_behavior can be set, please ignore it"]
    }
  }
}
