variable "project_name" {
  description = "Kurzname des Projekts, nur Kleinbuchstaben und Ziffern"
  type        = string
  default     = "nordwerk"

  validation {
    condition     = can(regex("^[a-z0-9]{3,14}$", var.project_name))
    error_message = "Nur Kleinbuchstaben und Ziffern, 3 bis 14 Zeichen."
  }
}

variable "environment" {
  description = "Umgebungskennung"
  type        = string
  default     = "dev"
}

variable "course_id" {
  description = "Kurskennung fuer Ressourcen-Tags"
  type        = string
  default     = "DLBSEPCP01"
}

variable "location" {
  description = "Azure-Region. Muss unter der Abonnementrichtlinie freigegeben sein."
  type        = string
  default     = "germanywestcentral"
}

variable "replication_type" {
  description = "Replikationsart. ZRS verteilt synchron ueber drei Verfuegbarkeitszonen."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS"], var.replication_type)
    error_message = "Zulaessig sind LRS, ZRS, GRS oder RAGRS."
  }
}

variable "versioning_enabled" {
  description = "Blobversionierung. Erlaubt Wiederherstellung nach fehlerhafter Aenderung."
  type        = bool
  default     = true
}

variable "retention_days" {
  description = "Aufbewahrung geloeschter Blobs und Container in Tagen"
  type        = number
  default     = 7

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "Zwischen 1 und 365 Tagen."
  }
}

variable "old_version_expiry_days" {
  description = "Nach wie vielen Tagen alte Blobversionen entfernt werden"
  type        = number
  default     = 30
}

variable "deploy_observability" {
  description = "Ueberwachungsebene bereitstellen"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Aufbewahrung im Log-Analytics-Arbeitsbereich in Tagen"
  type        = number
  default     = 30
}
