variable "project" {
  default = "sretask-446"
}

variable "project_id" {
  default = "114824334285"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}


variable "credentials" {
  default = "../sretask-446.json"
}

variable "machine_type" {
  default = "e2-small"
}

variable "SVC_ACCOUNT_KEY" {
  type        = string
  default     = "CHANGE_THE_KEY_HERE_IN ENCODED_FORMAT" // <<<<<<
  description = "service account encrypted key"
}


variable "stor_bucket" {
  type        = string
  default     = "sre-bkp-bucket"
  description = "Bucket to store the DB backup  files"
}

variable "dom_bucket" {
  type        = string
  default     = "sre-web-bucket"
  description = "Bucket to store the website static files"
}

variable "domain_name" {
  description = "Cloud DNS domain name"
  type        = string
  default     = "gcp.sretask.xyz."
}

variable "named_port" {
  description = "Custom ports to set on the Instances"
  type        = map(string)
  default = {
    "http" = "8001"
    "consul" = "8500"
  }
}


