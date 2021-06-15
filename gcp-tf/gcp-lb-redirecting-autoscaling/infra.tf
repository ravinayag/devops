# Bucket to store dabase backup files.
resource "google_storage_bucket" "gcp_sresite-bket" {
  provider = google
  name     = var.stor_bucket
  location = "US"
  force_destroy = true
  
  lifecycle_rule {
    condition {
      age = "1"
    }
    action {
      type = "Delete"
    }
  }
  retention_policy {
    retention_period = 1296000    // 15days 
  }
}


# Bucket to store static website files
resource "google_storage_bucket" "gcp_sresite" {
  provider = google
  name     = var.dom_bucket
  location = "US"
  force_destroy = true
}


# Make bucket objects to public
resource "google_storage_default_object_access_control" "gcp_website_read" {
  bucket = google_storage_bucket.gcp_sresite.name
  role   = "READER"
  entity = "allUsers"
}

# Reserve an external public IP
resource "google_compute_global_address" "gcp_website" {
  provider = google
  name     = "sresite-lb-ip"
}

# Registering the DNS zone
resource  "google_dns_managed_zone" "gcp_dns_zone" {
  provider = google-beta
  name     = "gcp-dns-zone"
  dns_name = var.domain_name
}

# Adding  the Public IP to the DNS entry
resource "google_dns_record_set" "gcp_website" {
  provider     = google
  name         = "www.${google_dns_managed_zone.gcp_dns_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.gcp_dns_zone.name
  rrdatas      = [google_compute_global_address.gcp_website.address]
}


resource "google_monitoring_alert_policy" "alert_policy" {
   provider              = google-beta
  display_name = "monitoring alert for 5xx"
  combiner     = "OR"
  enabled =  true
  conditions {
    display_name = "5xx responses [5TH PERCENTILE]"
    condition_threshold {
      comparison = "COMPARISON_GT"
      filter     = "metric.type=\"aws.googleapis.com/ELB/HTTPCode_Backend_5XX/Sum\" resource.type=\"aws_elb_load_balancer\""
      duration   = "0s"
      threshold_value = 5
      trigger {
          percent =  100
      }
      aggregations {
                alignment_period = "300s"
                cross_series_reducer = "REDUCE_PERCENTILE_05"
                per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}

