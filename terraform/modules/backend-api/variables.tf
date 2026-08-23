variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "name_prefix" { type = string }
variable "suffix" { type = string }

variable "function_source_dir" {
  description = "Verzeichnis mit dem Funktionscode"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
