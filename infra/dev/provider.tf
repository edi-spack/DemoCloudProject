terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.29.0"
    }
  }

  backend "gcs" {
    bucket = "terraform-state-dev-sdhjfsduniquesdj"
    prefix = "terraformState"
  }
}

provider "google" {
  # credentials = file(var.gcp_svc_key)
  project = var.gcp_project
  region  = var.gcp_region
}

provider "google-beta" {
  # credentials = file(var.gcp_svc_key)
  project = var.gcp_project
  region  = var.gcp_region
}
