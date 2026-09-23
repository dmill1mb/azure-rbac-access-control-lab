output "resource_group_name" {
  value = data.azurerm_resource_group.lab.name
}

output "vm_name" {
  value = data.azurerm_virtual_machine.fs01.name
}

output "vm_id" {
  value       = data.azurerm_virtual_machine.fs01.id
  description = "Full resource ID - the scope all three role assignments use."
}

output "rbac_summary" {
  sensitive   = true
  description = "Role assignment IDs - view with: terraform output -json rbac_summary"
  value = {
    owner       = azurerm_role_assignment.sysadmin_owner.id
    contributor = azurerm_role_assignment.supporttech_vm_contributor.id
    reader      = azurerm_role_assignment.auditor_reader.id
  }
}
