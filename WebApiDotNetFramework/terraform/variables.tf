variable "resource_group_location" {
  default     = "francecentral"
  description = "Location of the resource group."
}

variable "prefix" {
  type        = string
  default     = "win-vm-iis"
  description = "Prefix of the resource name"
}

variable "gh_pat" {
  type      = string
  sensitive = true
}

variable "gh_repo" {
  type    = string
  default = "WebApiDotNetFramework"
}

variable "gh_repo_owner"{
    type    = string
    default = "0GiS0"
}