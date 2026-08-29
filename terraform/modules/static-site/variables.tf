variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "suffix" { type = string }

variable "replication_type" {
  description = "ZRS fuer Zonenredundanz, LRS als guenstigere Testvariante"
  type        = string
  default     = "ZRS"
}

variable "website_source_path" {
  description = "Verzeichnis mit den auszuliefernden Dateien"
  type        = string
}

variable "versioning_enabled" {
  type    = bool
  default = true
}

variable "retention_days" {
  type    = number
  default = 7
}

variable "old_version_expiry_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
