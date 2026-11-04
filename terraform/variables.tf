variable "tenancy_ocid" {
  type        = string
  description = "OCID da tenancy trial do participante."
  validation {
    condition     = can(regex("^ocid1[.]tenancy[.]", var.tenancy_ocid))
    error_message = "Informe o OCID de uma tenancy."
  }
}

variable "region" {
  type        = string
  default     = "us-chicago-1"
  description = "Região assinada com AIDP disponível e quota na trial."
}

variable "lab_name" {
  type        = string
  default     = "lab-codex-aidp-rm"
  description = "Prefixo exclusivo para este ambiente descartável."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,39}$", var.lab_name))
    error_message = "Use 3 a 40 caracteres: letras minúsculas, números e hífen; comece com letra."
  }
}

variable "workspace_name" {
  type    = string
  default = "lab-validacao"
  validation {
    condition     = length(trimspace(var.workspace_name)) > 0
    error_message = "Informe um nome de workspace."
  }
}

variable "iam_wait_seconds" {
  type    = number
  default = 90
  validation {
    condition     = var.iam_wait_seconds >= 30 && var.iam_wait_seconds <= 600
    error_message = "Use entre 30 e 600 segundos para propagação inicial do IAM."
  }
}

variable "enable_ai_features" {
  type        = bool
  default     = false
  description = "Opcional: cria Lakehouse 26ai com 2 ECPUs e 1 TB e o associa ao AIDP. Desnecessário para os três notebooks; consome créditos adicionais."
}

variable "lakehouse_admin_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "Somente com enable_ai_features=true. Preencha no campo protegido do Resource Manager, nunca no ZIP."
}

variable "lakehouse_database_name" {
  type    = string
  default = "LABAIDP"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{0,13}$", var.lakehouse_database_name))
    error_message = "Use de 1 a 14 caracteres alfanuméricos, iniciando por letra."
  }
}

