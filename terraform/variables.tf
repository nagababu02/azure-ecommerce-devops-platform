variable "project_name" {
  default = "ecommerce-devops"
}

variable "location" {
  default = "uaenorth"
}

variable "acr_name" {
  description = "Must be globally unique, alphanumeric only (5-50 chars)"
  default     = "acrecommercedevops01"
}

variable "node_count" {
  default = 2
}

variable "node_vm_size" {
  default = "Standard_B2s"
}
