variable "project_name" {
  description = "Kurzname des Projekts, nur Kleinbuchstaben und Ziffern"
  type        = string
  default     = "cloudportfolio"

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
  default     = "DEIN-KURSKUERZEL"
}

variable "location" {
  description = "Azure-Region. Muss unter der Abonnementrichtlinie freigegeben sein."
  type        = string
  default     = "germanywestcentral"
}

variable "replication_type" {
  description = "Replikationsart des Speicherkontos, ZRS oder LRS"
  type        = string
  default     = "ZRS"
}

variable "deploy_edge" {
  description = "Front Door bereitstellen. Verursacht rund 35 USD Grundgebuehr je Monat."
  type        = bool
  default     = false
}

variable "deploy_backend" {
  description = "Function App und Tabelle bereitstellen"
  type        = bool
  default     = true
}
