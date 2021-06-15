variable "region" {}
variable "project" {}
variable "SVC_ACCOUNT_KEY" {}
variable "dom_bucket" {}
variable "stor_bucket" {}
variable "machine_type" {}
variable "named_port" {}

# Instance Group Manager for Managed autoscaling services
resource "google_compute_region_instance_group_manager" "gcp_igmgr" {
  name = "igmgr-${var.region}"

  base_instance_name = "sre-inst-${var.region}"
  region             = "${var.region}"

  version {
    name              = "ver-1.0"
    instance_template = google_compute_instance_template.ginst_tpl.self_link
  }


dynamic "named_port" {
    for_each = var.named_port
    content {
      name               = named_port.key
      port               = named_port.value
    }
  }

  auto_healing_policies {
    health_check      = google_compute_http_health_check.gcp_inst_hc_api.self_link
    initial_delay_sec = 60
  }
  timeouts {
    create = "10m"
    update = "10m"
  }
}


#Instance launch template 
resource "google_compute_instance_template" "ginst_tpl" {
    provider        = google
    name = "ginst-tmpl"
    machine_type = var.machine_type
    tags = ["sre-instance", "allow-lb-service"]
    region = var.region

    disk {
        source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
        auto_delete       = true
        boot              = true
    }

    network_interface {
        network = google_compute_network.sre-network.name
        subnetwork = google_compute_subnetwork.default.id
        access_config {
            // Ephemeral IP
       }  
    }

    metadata_startup_script = join("\n", [local.prereq_script, local.start_script] )

    lifecycle {
       create_before_destroy = true
    }
}


resource "google_compute_region_autoscaler" "gcp_autoscaler" {
  name   = "gcp-autoscale-${var.region}"
  target =  google_compute_region_instance_group_manager.gcp_igmgr.self_link

  autoscaling_policy  {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 180

    cpu_utilization {
      target = 0.9
    }
  }

  region = var.region
}

resource "google_compute_http_health_check" "gcp_inst_hc_api" {
  name         = "inst-hc-api-${var.region}"
  request_path = "/api/text"

  timeout_sec        = 5
  check_interval_sec = 5
  port               = 8001

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_http_health_check" "gcp_inst_hc_consul" {
  name         = "inst-hc-consul-${var.region}"
  request_path = "/ui/v1/agent/checks"

  timeout_sec        = 5
  check_interval_sec = 5
  port               = 8500

  lifecycle {
    create_before_destroy = true
  }
}

output "instance_group_manager" {
  value = "${google_compute_region_instance_group_manager.gcp_igmgr.instance_group}"
}

output "health_check_api" {
  value = "${google_compute_http_health_check.gcp_inst_hc_api.self_link}"
}

output "health_check_consul" {
  value = "${google_compute_http_health_check.gcp_inst_hc_consul.self_link}"
}


# bootstrap scripts to execute on instance launch
locals {
  
  prereq_script = templatefile("${path.module}/scripts/prereq.sh",{  
    stor_bucket = var.stor_bucket,
    dom_bucket = var.dom_bucket,
    SVC_ACCOUNT_KEY = var.SVC_ACCOUNT_KEY  })
  
  start_script = templatefile("${path.module}/scripts/startservice.sh", {  
    stor_bucket = var.stor_bucket,
    dom_bucket = var.dom_bucket,
    SVC_ACCOUNT_KEY = var.SVC_ACCOUNT_KEY  })

//  port_list = {http = 8001, consul = 8500, nginx = 80}

}
#Create the Default Network in VPC
resource "google_compute_network" "sre-network" {
  auto_create_subnetworks         = false
  delete_default_routes_on_create = false
  description                     = "Default network for the sretask"
  mtu                             = 0
  name                            = "default"
  project                         = var.project
  routing_mode                    = "REGIONAL"
}

resource "google_compute_subnetwork" "default" {
  name          = "sresite-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.sre-network.id
}

#Create the firewall Rule for externel net
resource "google_compute_firewall" "sre_fw_external" {
  name    = "srei-fw-external"
  network = google_compute_network.sre-network.id
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8001", "8500"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}
