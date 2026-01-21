variable "storage_class_name" {
  type = string
}

variable "storage_class_provisioner" {
  type = string
  default = "rancher.io/local-path"  # For local/on-prem clusters. Use "kubernetes.io/aws-ebs" for AWS
}

variable "storage_class_reclaim_policy" {
  type = string
  validation {
    condition = contains(["Delete", "Retain"], var.storage_class_reclaim_policy)
    error_message = "Invalid storage class reclaim policy supplied"
  }
  default = "Delete"
}

variable "storage_class_volume_binding_mode" {
  type = string
  validation {
    condition = contains(["WaitForFirstConsumer", "Immediate"], var.storage_class_volume_binding_mode)
    error_message = "Invalid storage class volume binding mode supplied"
  }
  default = "WaitForFirstConsumer"
}
