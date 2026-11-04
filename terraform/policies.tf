# Não cria usuários, grupos ou credenciais. O operador usa a sessão autenticada do Resource Manager na própria trial.
# Estas autorizações são do SERVIÇO AIDP, não uma concessão administrativa a participantes.
resource "oci_identity_policy" "service_iam" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = "${var.lab_name}-service-iam"
  description    = "Inspeção IAM e uso de tags exigidos pelo serviço AIDP."
  freeform_tags  = local.tags
  statements = [
    "Allow any-user to {AUTHENTICATION_INSPECT, DOMAIN_INSPECT, DOMAIN_READ, DYNAMIC_GROUP_INSPECT, GROUP_INSPECT, GROUP_MEMBERSHIP_INSPECT, USER_INSPECT, USER_READ} in tenancy where all {request.principal.type='aidataplatform'}",
    "Allow any-user to {TAG_NAMESPACE_USE} in tenancy where all {request.principal.type='aidataplatform'}",
  ]
  depends_on = [oci_identity_compartment.lab]
}

resource "oci_identity_policy" "service_compartment" {
  provider       = oci.home
  compartment_id = oci_identity_compartment.lab.id
  name           = "${var.lab_name}-service-data"
  description    = "Acesso do serviço AIDP a dados, logs e métricas somente no compartment do lab."
  freeform_tags  = local.tags
  statements = concat([
    "Allow any-user to manage log-groups in compartment id ${oci_identity_compartment.lab.id} where all {request.principal.type='aidataplatform'}",
    "Allow any-user to read log-content in compartment id ${oci_identity_compartment.lab.id} where all {request.principal.type='aidataplatform'}",
    "Allow any-user to use metrics in compartment id ${oci_identity_compartment.lab.id} where all {request.principal.type='aidataplatform', target.metrics.namespace='oracle_aidataplatform'}",
    "Allow any-user to manage buckets in compartment id ${oci_identity_compartment.lab.id} where all {request.principal.type='aidataplatform', any {request.permission='BUCKET_CREATE', request.permission='BUCKET_INSPECT', request.permission='BUCKET_READ', request.permission='BUCKET_UPDATE'}}",
    "Allow any-user to manage buckets in compartment id ${oci_identity_compartment.lab.id} where all {request.principal.id=target.resource.tag.orcl-aidp.governingAidpId, any {request.permission='BUCKET_DELETE', request.permission='PAR_MANAGE', request.permission='RETENTION_RULE_LOCK', request.permission='RETENTION_RULE_MANAGE'}}",
    "Allow any-user to read objectstorage-namespaces in compartment id ${oci_identity_compartment.lab.id} where all {request.principal.type='aidataplatform', request.permission='OBJECTSTORAGE_NAMESPACE_READ'}",
    "Allow any-user to manage objects in compartment id ${oci_identity_compartment.lab.id} where all {request.principal.id=target.bucket.system-tag.orcl-aidp.governingAidpId}",
    ], var.enable_ai_features ? [
    "Allow any-user to use generative-ai-family in compartment id ${oci_identity_compartment.lab.id} where all {request.principal.type='aidataplatform'}",
  ] : [])
}
