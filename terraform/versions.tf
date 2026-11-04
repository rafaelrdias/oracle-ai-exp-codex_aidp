terraform {
  required_version = "~> 1.5.0"
  required_providers {
    oci  = { source = "oracle/oci", version = "= 9.11.0" }
    time = { source = "hashicorp/time", version = "~> 0.13.0" }
  }
}
