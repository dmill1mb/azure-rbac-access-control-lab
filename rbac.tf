# Azure RBAC (Role-Based Access Control) controls who can manage
# FS01 *from Azure* - an entirely separate question from who can
# read the files inside it, which is what Lab 1's NTFS permissions
# handle. RBAC lives at the Azure Resource Manager control plane.
# NTFS lives inside the operating system. Different identity
# systems, different enforcement engines.
#
# The `scope` line is the single most important line in each block.

# Owner: full control of FS01, including granting and revoking
# other people's access to it.
#
# Note: in production you'd usually assign Contributor and User
# Access Administrator separately rather than Owner, so that the
# ability to change permissions is its own deliberate grant.
resource "azurerm_role_assignment" "sysadmin_owner" {
  scope                = data.azurerm_virtual_machine.fs01.id
  role_definition_name = "Owner"
  principal_id         = var.sysadmin_object_id
}

# Virtual Machine Contributor: start, stop, restart, resize FS01.
# Cannot delete it and cannot touch RBAC. This is the right role
# for help desk staff who keep servers available but shouldn't be
# able to reconfigure or remove them.
resource "azurerm_role_assignment" "supporttech_vm_contributor" {
  scope                = data.azurerm_virtual_machine.fs01.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = var.support_user_object_id
}

# Reader: look, don't touch. No actions of any kind. Appropriate
# for auditors who need visibility without any ability to change
# what they're auditing.
resource "azurerm_role_assignment" "auditor_reader" {
  scope                = data.azurerm_virtual_machine.fs01.id
  role_definition_name = "Reader"
  principal_id         = var.auditor_object_id
}
