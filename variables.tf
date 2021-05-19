variable "prefix" {
  type        = string
  description = "A namespace prefix to be used for all resources"
}

variable "location" {
  type        = string
  description = "The Azure Region in which all resources should be provisioned"
}

variable "cluster_azure_ad_groups" {
  type        = list
  description = "Azure AD groups for your cluster administrators"
}

variable "cluster_azure_ad_tenant_id" {
  type        = string
  description = "The Azure AD tenant id"
}

variable cluster_vm_size {
  type        = string
  description = "size of cluster VMs"
}

variable cluster_vm_min_count {
  type        = number
  description = "minimum number of required cluster VMs"
}

variable cluster_vm_max_count {
  type        = number
  description = "maximum number of required cluster VMs"
}

variable win_vm_count {
  type        = number
  default     = 0
  description = "number of required windows VM"
}

variable win_vm_size {
  type        = string
  description = "size of windows VMs"
}

variable win_vm_private_ip {
  type        = list
  description = "list of private IPs to allocate to each windows VM"
}

variable linux_vm_count {
  type        = number
  default     = 0
  description = "number of required linux VM"
}

variable linux_vm_size {
  type        = string
  description = "size of linux VMs"
}

variable linux_vm_private_ip {
  type        = list
  description = "list of private IPs to allocate to each linux VM"
}

variable secondary_resource_group {
  type        = string  
  description = "secondary resource group used for storing book-keeping resources"
}

