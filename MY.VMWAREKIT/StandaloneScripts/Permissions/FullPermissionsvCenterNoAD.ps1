<#
.SYNOPSIS
    Export vCenter permissions: Users/Groups, Roles, Entities.

.DESCRIPTION
    For each permission in one or more vCenters, this script outputs:
      - vCenter
      - Entity (name, type, inventory path)
      - Role
      - Principal (user or group, e.g. domain\user or domain\group)
      - Whether the principal is a group
      - Propagate flag

    No AD module, no group expansion – just what vCenter itself stores.

.EXAMPLE
    .\Export-vCenterPermissions.ps1 -vCenters vcsa01.lab.local -OutputPath .\vcenter-perms.csv
#>

param(
    [Parameter(Mandatory = $true)]
    [string[]]$vCenters,

    [string]$OutputPath = ".\vCenter-Permissions.csv"
)

# --- Pre-flight checks ---
Write-Host "Checking for PowerCLI..." -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name VMware.PowerCLI)) {
    throw "VMware.PowerCLI module not found. Please install/import PowerCLI first."
}

# Import-Module VMware.PowerCLI -ErrorAction Stop

# --- Helper: Connect to vCenters (reuse session if it exists) ---
function Connect-ToVCenters {
    param (
        [string[]]$Servers
    )

    foreach ($vc in $Servers) {
        if (-not (Get-VIServer -Server $vc -ErrorAction SilentlyContinue)) {
            Write-Host "Connecting to $vc..." -ForegroundColor Yellow
            Connect-VIServer -Server $vc | Out-Null
        } else {
            Write-Host "Already connected to $vc." -ForegroundColor Green
        }
    }
}

# --- Helper: Build a readable inventory path for an object (best-effort) ---
function Get-InventoryPath {
    param(
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl]$Object
    )

    if (-not $Object) { return $null }

    $path = $Object.Name
    $parent = $Object.Parent

    while ($parent) {
        $parentObj = Get-Inventory -Id $parent.Id -ErrorAction SilentlyContinue
        if (-not $parentObj) { break }
        $path = "$($parentObj.Name)/$path"
        $parent = $parentObj.Parent
    }

    return $path
}

# --- MAIN ---
# Connect-ToVCenters -Servers $vCenters

$finalResults = @()

foreach ($vc in $vCenters) {
    Write-Host "Collecting permissions from $vc..." -ForegroundColor Cyan

    $serverObj = Get-VIServer -Server $vc -ErrorAction Stop

    # Get all permissions from this vCenter
    $perms = Get-VIPermission -Server $serverObj

    foreach ($perm in $perms) {
        $entity    = $perm.Entity
        $entityInv = Get-Inventory -Id $entity.Id -ErrorAction SilentlyContinue

        $entityName = $entityInv.Name
        $entityType = $entityInv.Type
        $entityPath = Get-InventoryPath -Object $entityInv

        $finalResults += [PSCustomObject]@{
            vCenter          = $serverObj.Name
            EntityName       = $entityName
            EntityType       = $entityType
            EntityPath       = $entityPath
            Role             = $perm.Role
            Principal        = $perm.Principal   # user or group (e.g. DOMAIN\User or DOMAIN\Group)
            PrincipalIsGroup = $perm.IsGroup
            Propagate        = $perm.Propagate
        }
    }
}

Write-Host "Total permission rows: $($finalResults.Count)" -ForegroundColor Green

# Output
$finalResults |
    Sort-Object vCenter, Principal, EntityPath, Role |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Export complete: $OutputPath" -ForegroundColor Green
