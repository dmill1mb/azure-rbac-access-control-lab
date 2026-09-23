variable "resource_group_name" {
  description = "Must match Lab 1 exactly - case-sensitive."
  type        = string
  default     = "RG-FileServerLab"
}

variable "vm_name" {
  description = "Must match Lab 1 exactly - case-sensitive. FS01 is not the same as fs01."
  type        = string
  default     = "FS01"
}

# The three Object ID variables below have NO default on purpose.
# A placeholder default would let a careless apply hand real roles
# to the wrong identity. With no default, Terraform stops and
# demands a value instead of guessing.

variable "sysadmin_object_id" {
  description = "Entra ID Object ID for the SysAdmin persona - receives Owner on FS01."
  type        = string
}

variable "support_user_object_id" {
  description = "Entra ID Object ID for the SupportTech persona - receives Virtual Machine Contributor on FS01."
  type        = string
}

variable "auditor_object_id" {
  description = "Entra ID Object ID for the Auditor persona - receives Reader on FS01."
  type        = string
}
