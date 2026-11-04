locals {
  tags = { Project = "codex-aidp-lab", ManagedBy = "terraform", Environment = "trial-test", Lab = var.lab_name }
}

resource "oci_identity_compartment" "lab" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = replace(var.lab_name, "-", "_")
  description    = "Ambiente descartável do laboratório Codex e AIDP; gerenciado por Terraform."
  enable_delete  = true
  freeform_tags  = local.tags
  lifecycle {
    precondition {
      condition = anytrue([
        for r in data.oci_identity_region_subscriptions.tenancy.region_subscriptions :
        r.region_name == var.region && r.state == "READY"
      ])
      error_message = "A região de destino deve estar assinada e READY nesta tenancy."
    }
  }
}

resource "time_sleep" "iam" {
  depends_on      = [oci_identity_policy.service_iam, oci_identity_policy.service_compartment]
  create_duration = "${var.iam_wait_seconds}s"
  triggers = {
    policies = sha256(jsonencode(concat(
      oci_identity_policy.service_iam.statements,
      oci_identity_policy.service_compartment.statements
    )))
  }
}

resource "oci_database_autonomous_database" "lakehouse" {
  count          = var.enable_ai_features ? 1 : 0
  compartment_id = oci_identity_compartment.lab.id
  display_name   = "${var.lab_name}-lakehouse"
  db_name        = var.lakehouse_database_name
  db_workload    = "LH"
  db_version     = "26ai"
  compute_model  = "ECPU"
  compute_count  = 2
  # Lakehouse (LH) exige armazenamento em TB; o mínimo é 1 TB.
  data_storage_size_in_tbs            = 1
  is_free_tier                        = false
  is_auto_scaling_enabled             = false
  is_auto_scaling_for_storage_enabled = false
  is_mtls_connection_required         = true
  license_model                       = "LICENSE_INCLUDED"
  admin_password                      = var.lakehouse_admin_password
  freeform_tags                       = local.tags
  lifecycle {
    precondition {
      condition     = try(length(var.lakehouse_admin_password) >= 12, false)
      error_message = "Para habilitar IA, forneça lakehouse_admin_password válida, com ao menos 12 caracteres."
    }
  }
  timeouts {
    create = "120m"
    delete = "120m"
  }
}

resource "oci_ai_data_platform_ai_data_platform" "lab" {
  compartment_id         = oci_identity_compartment.lab.id
  display_name           = var.lab_name
  default_workspace_name = var.workspace_name
  is_enable_ai_feature   = var.enable_ai_features
  vector_db_id           = var.enable_ai_features ? oci_database_autonomous_database.lakehouse[0].id : null
  vector_db_admin_cred   = var.enable_ai_features ? var.lakehouse_admin_password : null
  freeform_tags          = local.tags
  depends_on             = [time_sleep.iam]
  timeouts {
    create = "120m"
    update = "120m"
    delete = "120m"
  }
}
