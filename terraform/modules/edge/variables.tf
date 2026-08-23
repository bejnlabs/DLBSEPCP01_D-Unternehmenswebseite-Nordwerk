variable "resource_group_name" { type = string }
variable "name_prefix" { type = string }
variable "suffix" { type = string }

variable "origin_host_name" {
  description = "Hostname des Ursprungs fuer statische Inhalte"
  type        = string
}

variable "api_host_name" {
  description = "Hostname der Function App. Null, wenn kein Backend bereitgestellt wird."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "Tarif des Profils. Premium waere fuer private Anbindung noetig."
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "tags" {
  type    = map(string)
  default = {}
}
