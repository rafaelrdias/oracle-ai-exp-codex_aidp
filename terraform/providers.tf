# Autenticação fornecida pelo OCI Resource Manager; não enviar PEM ou API key.
provider "oci" {
  region = var.region
}

# IAM writes must use the tenancy home region, which can differ from the AIDP region.
data "oci_identity_region_subscriptions" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

locals {
  home_region = one([
    for r in data.oci_identity_region_subscriptions.tenancy.region_subscriptions :
    r.region_name if r.is_home_region
  ])
}

provider "oci" {
  alias  = "home"
  region = local.home_region
}
