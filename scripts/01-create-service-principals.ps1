<#
    01-create-service-principals.ps1

    Creates three service principals - one per persona - with NO role
    assigned. Terraform grants the roles; that's the point of the lab.

    Three objects get created per persona, and the difference matters:
      1. App registration - the definition of the application.
      2. Service principal - that application's identity in THIS tenant.
      3. Client secret     - the password the SP authenticates with.

    The ID Terraform needs is the SERVICE PRINCIPAL's object ID.
    NOT the appId. They are different GUIDs and mixing them up is the
    most common way this lab fails.
#>

$vaultName = "kv-fslab-demarcus21"   # reusing Lab 1's Key Vault

$personas = @(
    @{ Name = "rbac-lab-sysadmin";    VarName = "sysadmin_object_id"     },
    @{ Name = "rbac-lab-supporttech"; VarName = "support_user_object_id" },
    @{ Name = "rbac-lab-auditor";     VarName = "auditor_object_id"      }
)

$results = @()

foreach ($p in $personas) {
    Write-Host "`nCreating $($p.Name)..." -ForegroundColor Cyan

    # 1. App registration
    $appId = az ad app create --display-name $p.Name --query appId -o tsv

    # 2. Service principal for that app, in this tenant
    az ad sp create --id $appId --output none

    # 3. The object ID Terraform actually wants
    $objectId = az ad sp show --id $appId --query id -o tsv

        # 4. A client secret, parked in Key Vault rather than left on screen
    $secret = az ad app credential reset --id $appId --query password -o tsv
    if ([string]::IsNullOrWhiteSpace($secret)) {
        throw "Credential reset returned nothing for $($p.Name) - stopping instead of reporting a success that didn't happen."
    }
    az keyvault secret set --vault-name $vaultName `
        --name "$($p.Name)-secret" --value $secret --output none
    if ($LASTEXITCODE -ne 0) {
        throw "Key Vault write failed for $($p.Name)."
    }

    $results += @{ VarName = $p.VarName; AppId = $appId; ObjectId = $objectId }
    Write-Host "  appId     : $appId"    -ForegroundColor DarkGray
    Write-Host "  objectId  : $objectId" -ForegroundColor Green
    Write-Host "  secret    : stored in Key Vault as $($p.Name)-secret"
}

Write-Host "`n=== Paste these into terraform.tfvars ===" -ForegroundColor Yellow
foreach ($r in $results) {
    Write-Host "$($r.VarName.PadRight(23)) = `"$($r.ObjectId)`""
}