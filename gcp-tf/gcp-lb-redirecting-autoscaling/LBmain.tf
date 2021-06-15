#URL redirection  for Loadbalancing 
resource "google_compute_url_map" "gcp_website" {
  provider        = google
  name            = "sresite-url-mapping"

  host_rule {
    hosts        = [google_dns_record_set.gcp_website.name, google_compute_global_address.gcp_website.address ]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.gcp_website.self_link

    path_rule {
      paths   = ["/api", "/api/*"]
      service = google_compute_backend_service.gcp_website_api.self_link
    }
    path_rule {
      paths   = ["/ui/*", "/ui"]
      service = google_compute_backend_service.gcp_website_ui.self_link
    }
  }
  default_service = google_compute_backend_bucket.gcp_website.self_link
}

#SSL certificate creation
resource "google_compute_managed_ssl_certificate" "gcp_website" {
  provider = google-beta
  name     = "gcp-ssl-certs"
  managed {
    domains = [google_dns_record_set.gcp_website.name]
  }
}

# proxy for http
resource "google_compute_target_http_proxy" "gcp_website" {
  provider         = google
  name             = "http-proxy"
  url_map          = google_compute_url_map.gcp_website.self_link
}

# forwarding rule - http
resource "google_compute_global_forwarding_rule" "http" {
  provider              = google
  name                  = "sresite-forwarding-rule-b"
  ip_address            = google_compute_global_address.gcp_website.address
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.gcp_website.self_link
  depends_on            = [google_compute_global_address.gcp_website]
}


# proxy for https
resource "google_compute_target_https_proxy" "gcp_website" {
  provider         = google
  name             = "https-proxy"
  url_map          = google_compute_url_map.gcp_website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.gcp_website.self_link]
}

# forwarding rule - https
resource "google_compute_global_forwarding_rule" "https" {
  provider              = google
  name                  = "sresite-forwarding-rule-a"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.gcp_website.address
  #ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.gcp_website.self_link
  depends_on = [google_compute_global_address.gcp_website]
}

#Module for the instance baackend 

module "instance-group-region-a" {
  source = "./instancebackend"
  region = var.region
  project = var.project
  SVC_ACCOUNT_KEY = var.SVC_ACCOUNT_KEY
  machine_type = var.machine_type
  stor_bucket = var.stor_bucket
  dom_bucket = var.dom_bucket
  named_port = var.named_port
}


output "ip-address" {
  value = google_compute_global_address.gcp_website.address
}




