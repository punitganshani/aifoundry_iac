variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vnet_name" {
  type    = string
  default = "vnet-ai-foundry"
}

variable "address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}
