<#
    validate-lab.ps1

    Checks the role assignments Azure is actually holding on FS01 -
    not what Terraform reported creating.

    What this proves:  each expected role is assigned to the expected
                       principal, directly at FS01's scope, and nothing
                       else is assigned there.
    What it can't:     that those permissions are ENFORCED. Only signing
                       in as each identity and attempting actions proves
                       that - see "Persona testing" in the README.

    Expected object IDs are read from terraform.tfvars, so this checks
    against the same values Terraform deployed.
#>

param(
    [string]$ResourceGroup = "RG-FileServerLab",
    [string]$VMName        = "FS01",
    [string]$TfVarsPath    = ".\terraform.tfvars"
)

$log = [System.Collections.Generic.List[string]]::new()
function Say([string]$Text, [string]$Color = "Gray") {
    Write-Host $Text -ForegroundColor $Color
    $log.Add($Text)
}

function Get-TfVar([string]$Name) {
    $hit = Select-String -Path $TfVarsPath -Pattern "^\s*$Name\s*=\s*`"([^`"]+)`"" | Select-Object -First 1
    if (-not $hit) { throw "Could not find $Name in $TfVarsPath." }
    return $hit.Matches[0].Groups[1].Value
}

Say "`n=== RBAC Lab Validation ===" "Cyan"

if (-not (Test-Path $TfVarsPath)) { throw "$TfVarsPath not found - run this from the project folder." }

$vmId = az vm show -g $ResourceGroup -n $VMName --query id -o tsv
if ($LASTEXITCODE -ne 0 -or -not $vmId) {
    throw "VM $VMName not found in $ResourceGroup. Is Lab 1 deployed, and are you signed in as yourself?"
}
Say "Scope: $vmId"

$assignments = az role assignment list --scope $vmId `
    --query "[].{role:roleDefinitionName, principalId:principalId, scope:scope}" -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw "Could not list role assignments on $VMName." }

# Only assignments made directly on FS01 - not ones inherited from above
$direct = @($assignments | Where-Object { $_.scope -ieq $vmId })

$expected = @(
    @{ Label = "SysAdmin";    Role = "Owner";                       PrincipalId = Get-TfVar "sysadmin_object_id" },
    @{ Label = "SupportTech"; Role = "Virtual Machine Contributor"; PrincipalId = Get-TfVar "support_user_object_id" },
    @{ Label = "Auditor";     Role = "Reader";                      PrincipalId = Get-TfVar "auditor_object_id" }
)

$allPass = $true

Say "`n[ Expected assignments ]" "White"
foreach ($e in $expected) {
    $match = $direct | Where-Object { $_.role -eq $e.Role -and $_.principalId -eq $e.PrincipalId }
    if ($match) {
        Say "  [PASS] $($e.Label): $($e.Role) -> $($e.PrincipalId)" "Green"
    } else {
        Say "  [FAIL] $($e.Label): no $($e.Role) assignment for $($e.PrincipalId) on $VMName" "Red"
        $allPass = $false
    }
}

Say "`n[ Unexpected assignments ]" "White"
$extras = @($direct | Where-Object {
    $a = $_
    -not ($expected | Where-Object { $_.Role -eq $a.role -and $_.PrincipalId -eq $a.principalId })
})
if ($extras.Count -eq 0) {
    Say "  [PASS] Nothing else is assigned directly on $VMName" "Green"
} else {
    foreach ($x in $extras) { Say "  [FAIL] Unexpected: $($x.role) -> $($x.principalId)" "Red" }
    $allPass = $false
}

$overall = if ($allPass) { "ALL PASS" } else { "FAILURES DETECTED" }
Say "`nOverall: $overall" $(if ($allPass) { "Green" } else { "Red" })
Say "Assignments verified. Enforcement is proven separately - see Persona testing in the README." "Cyan"

$report = "RBAC Lab Validation Report`nGenerated: $(Get-Date)`n" + ($log -join "`n")
$report | Out-File ".\RBAC_Lab_Report.txt" -Encoding UTF8
Write-Host "Report exported: RBAC_Lab_Report.txt" -ForegroundColor Cyan

if (-not $allPass) { exit 1 }