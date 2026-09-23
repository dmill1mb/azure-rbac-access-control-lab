# Data sources READ existing infrastructure. They never create,
# modify, or destroy it. This is how one Terraform project safely
# references another project's resources - the pattern you'd use
# when your team's config needs something another team built.
#
# If Lab 1 isn't deployed, these fail immediately with a clear
# error rather than silently doing something unexpected.

data "azurerm_resource_group" "lab" {
  name = var.resource_group_name
}

# Reading FS01 gives us its full Azure resource ID, which looks like:
#
#   /subscriptions/<sub-id>/resourceGroups/RG-FileServerLab/
#     providers/Microsoft.Compute/virtualMachines/FS01
#
# That ID is the scope for every role assignment in rbac.tf.
#
#   Scope = the VM ID  ->  role applies to FS01 and nothing else.
#   Scope = the RG ID  ->  role silently applies to DC01 and
#                          CLIENT01 too. Same three lines of code,
#                          wildly different blast radius.

data "azurerm_virtual_machine" "fs01" {
  name                = var.vm_name
  resource_group_name = data.azurerm_resource_group.lab.name
}
