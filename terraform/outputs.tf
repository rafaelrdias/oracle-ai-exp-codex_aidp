output "compartment_id" { value = oci_identity_compartment.lab.id }
output "aidp_instance_id" { value = oci_ai_data_platform_ai_data_platform.lab.id }
output "region" { value = var.region }
output "home_region" { value = local.home_region }
output "workspace_name" { value = var.workspace_name }
output "lakehouse_id" {
  value = var.enable_ai_features ? oci_database_autonomous_database.lakehouse[0].id : null
}
output "console_url" {
  value = "https://cloud.oracle.com/aidataplatform?region=${var.region}"
}
output "next_step" {
  value = "Abra o workspace ${var.workspace_name} e crie labspark pelo Codex/Workbench. Esta stack não cria o Spark."
}
