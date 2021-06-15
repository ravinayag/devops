# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "gcp_website" {
  provider    = google
  name        = "gcp-website-backend"
  description = "Contains static files for sresite"
  bucket_name = google_storage_bucket.gcp_sresite.name
  enable_cdn  = true
}


resource "google_compute_backend_service" "gcp_website_api" {
  name             = "instance-backend-api"
  description      = "regional instance backend"
  protocol         = "HTTP"
  port_name        = "http"
  #timeout_sec      = 30
  session_affinity = "NONE"

  backend {
    group = module.instance-group-region-a.instance_group_manager
  }

  enable_cdn = true

  health_checks = [module.instance-group-region-a.health_check_api]
}

resource "google_compute_backend_service" "gcp_website_ui" {
  name             = "instance-backend-consul"
  description      = "regional instance backend"
  protocol         = "HTTP"
  port_name        = "consul"
  timeout_sec      = 30
  session_affinity = "NONE"

  backend {
    group = module.instance-group-region-a.instance_group_manager
  }

  enable_cdn = true

  health_checks = [module.instance-group-region-a.health_check_consul]
}
