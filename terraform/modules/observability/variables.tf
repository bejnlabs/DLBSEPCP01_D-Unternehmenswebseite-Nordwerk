variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "suffix" { type = string }

variable "storage_account_id" {
  description = "Speicherkonto, dessen Zugriffe protokolliert werden"
  type        = string
}

variable "retention_days" {
  description = "Aufbewahrung im Arbeitsbereich in Tagen"
  type        = number
  default     = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
