# Reuses Lab 1's existing state storage account - no new storage needed.
# The ONLY difference from Lab 1's backend is the key. Two state files
# living in the same container, completely independent of each other.
#
# Lab 1 uses: ntfs-lab.tfstate
# Lab 2 uses: rbac-lab.tfstate
#
# This separation is the whole point: `terraform destroy` here removes
# three role assignments and nothing else. Lab 1's VMs never notice.

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatelabs363689"
    container_name       = "tfstate"
    key                  = "rbac-lab.tfstate"
  }
}
