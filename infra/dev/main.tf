resource "google_cloudbuild_trigger" "develop-push-trigger" {
  name = "develop-push-trigger"
  location = "global"

  github {
    owner = "edi-spack"
    name  = "DemoCloudProject"

    push {
      branch = "develop"
    }
  }

  filename = "cloudbuild.dev.yaml"

  service_account = google_service_account.cloudbuild-service-account.id

  # build {
  #   options {
  #     default_logs_bucket_behavior = "REGIONAL_USER_OWNED_BUCKET"
  #   }
  #
  #   step {
  #     name = "gcr.io/cloud-builders/gcloud"
  #     args = ["echo", "This step is only required so default_logs_bucket_behavior can be set, please ignore it"]
  #   }
  # }
}

resource "google_artifact_registry_repository" "docker-repo" {
  location      = var.region
  repository_id = "docker-repo"
  description   = "Docker repository for project images"
  format        = "DOCKER"

  docker_config {
    immutable_tags = false
  }
}

resource "google_artifact_registry_repository_iam_member" "cloud-build-push-to-docker-repo-permission" {
  repository = google_artifact_registry_repository.docker-repo.id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cloudbuild-service-account.email}"
}

# Reserve a static external IP
resource "google_compute_global_address" "gateway-static-ip-dev" {
  name         = "gateway-static-ip-dev"
  address_type = "EXTERNAL"
}

# Instance Template with container
resource "google_compute_instance_template" "gateway-vm-template-dev" {
  name           = "gateway-vm-template-dev"
  region         = var.region
  machine_type   = "e2-micro"

  tags = ["http-server"]

  metadata = {
    "gce-container-declaration" = <<-EOT
      spec:
        containers:
          - name: app
            image: ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker-repo.name}/gateway-dev:latest
            stdin: false
            tty: false
            ports:
              - containerPort: 80
        restartPolicy: Always
    EOT
  }

  service_account {
    email  = google_service_account.compute-service-account.email
    scopes = ["cloud-platform"]
  }

  disk {
    source_image = "projects/cos-cloud/global/images/family/cos-stable"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {}
  }
}

# Regional MIG
resource "google_compute_region_instance_group_manager" "gateway-mig-dev" {
  name               = "gateway-mig-dev"
  base_instance_name = "gateway-dev"
  region             = var.region

  version {
    instance_template = google_compute_instance_template.gateway-vm-template-dev.self_link
  }

  target_size = 1

  auto_healing_policies {
    health_check      = google_compute_health_check.gateway-health-check-dev.self_link
    initial_delay_sec = 60
  }

  named_port {
    name = "http"
    port = 80
  }

  # update_policy {
  #   type                  = "PROACTIVE"
  #   minimal_action        = "REPLACE"
  #   max_surge_fixed       = 0
  #   max_unavailable_fixed = 5 # Must be >= number of zones (which i think is 3)
  #   replacement_method    = "RECREATE"
  # }
}

# Health check
# resource "google_compute_region_health_check" "gateway-health-check-dev" {
resource "google_compute_health_check" "gateway-health-check-dev" {
  name               = "gateway-health-check-dev"
  check_interval_sec = 60
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2

  http_health_check {
    port = 80
    request_path = "/"
  }
}

# Backend service
resource "google_compute_backend_service" "gateway-backend-service-dev" {
  name                  = "gateway-backend-service-dev"
  # region                = var.region
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.gateway-health-check-dev.self_link]

  backend {
    group = google_compute_region_instance_group_manager.gateway-mig-dev.instance_group
  }
}

# URL Map
resource "google_compute_url_map" "gateway-url-map-dev" {
  name            = "gateway-url-map-dev"
  default_service = google_compute_backend_service.gateway-backend-service-dev.self_link
}

# Target HTTP Proxy
resource "google_compute_target_http_proxy" "gateway-lb-proxy-dev" {
  name   = "gateway-lb-proxy-dev"
  url_map = google_compute_url_map.gateway-url-map-dev.self_link
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "gateway-forwarding-rule-dev" {
  name                  = "gateway-forwarding-rule-dev"
  ip_address            = google_compute_global_address.gateway-static-ip-dev.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.gateway-lb-proxy-dev.self_link
  load_balancing_scheme = "EXTERNAL"
}

#######
# Get the managed DNS zone
data "google_dns_managed_zone" "dns-zone" {
  name = var.dns_managed_zone_name
}

# Add the IP to the DNS
resource "google_dns_record_set" "gateway-dns-record-dev" {
  name         = "dev.${data.google_dns_managed_zone.dns-zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns-zone.name
  rrdatas      = [google_compute_global_address.gateway-static-ip-dev.address]
}
#######
