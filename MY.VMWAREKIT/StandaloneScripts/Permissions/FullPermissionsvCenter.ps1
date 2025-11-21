<#
.SYNOPSIS
    Export resultant vCenter permissions with AD group resolution.

.DESCRIPTION
    For each permission in one or more vCenters, this script outputs:
      - vCenter
      - Entity (name, type)
      - Role
      - Principal (user or group)
      - Whether it’s a group
      - AD user members of that group (resolved)
      - Whether the permission is direct or via group

    Requires:
      - VMware PowerCLI
      - ActiveDirectory module (RSAT) on a domain-joined machine

.EXAMPLE
    .\Export-vCenterPermissionsResolved.ps1 -vCenters vcsa01.lab.local -OutputPath .\vcenter-perms.csv
#>

param(
    [Parameter(Mandatory = $true)]
    [string[]]$vCenters,

    [string]$OutputPath = ".\vCenter-Permissions-Resolved.csv",

    # If you want to force which domain to query (optional)
    [string]$ADDomain = $null,

    # Disable recursive AD group expansion if you want only direct members
    [switch]$NoRecursive
)

# --- Pre-flight checks ---
Write-Host "Checking for PowerCLI..." -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name VMware.PowerCLI)) {
    throw "VMware.PowerCLI module not found. Please install/import PowerCLI first."
}

Write-Host "Checking for ActiveDirectory module..." -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    throw "ActiveDirectory module not found. Install RSAT / AD tools on this machine."
}

Import-Module VMware.PowerCLI -ErrorAction Stop
Import-Module ActiveDirectory -ErrorAction Stop

$recursive = -not $NoRecursive

# --- Helper: Connect to vCenters (reusing existing sessions if present) ---
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

# --- Helper: Resolve AD group members to user SamAccountNames ---
function Resolve-ADGroupMembers {
    param(
        [string]$GroupName,     # SamAccountName or 'domain\sam'
        [bool]$Recursive = $true,
        [string]$Domain = $null
    )

    $domainPart = $null
    $samPart    = $GroupName

    if ($GroupName -match '\\') {
        $domainPart, $samPart = $GroupName.Split('\', 2)
    }

    # Prefer explicit domain parameter, otherwise use parsed domain if present
    $adServer = $null
    if ($Domain) {
        $adServer = $Domain
    } elseif ($domainPart) {
        $adServer = $domainPart
    }

    try {
        $groupParams = @{
            Identity   = $samPart
            ErrorAction = 'Stop'
        }
        if ($adServer) {
            $groupParams['Server'] = $adServer
        }

        $group = Get-ADGroup @groupParams

        $memberParams = @{
            Identity   = $group
            ErrorAction = 'Stop'
            Recursive  = $Recursive
        }
        if ($adServer) {
            $memberParams['Server'] = $adServer
        }

        $members = Get-ADGroupMember @memberParams | Where-Object { $_.objectClass -eq 'user' }

        $results = @()
        foreach ($m in $members) {
            # Build "domain\sam" if we know the domain, else just use sam
            $userDomain = $m.SID.AccountDomainSid.Value
            try {
                $adUser = Get-ADUser -Identity $m.DistinguishedName -Properties SamAccountName -Server $adServer -ErrorAction Stop
                if ($adServer) {
                    $results += "$adServer\$($adUser.SamAccountName)"
                } elseif ($domainPart) {
                    $results += "$domainPart\$($adUser.SamAccountName)"
                } else {
                    $results += $adUser.SamAccountName
                }
            } catch {
                # Fallback – just emit the name
                $results += $m.Name
            }
        }
        return $results
    } catch {
        Write-Warning "Failed to resolve AD group '$GroupName': $($_.Exception.Message)"
        return @()
    }
}

# --- Helper: Get a nice inventory path for an entity (best-effort) ---
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
Connect-ToVCenters -Servers $vCenters

$finalResults = @()

foreach ($vc in $vCenters) {
    Write-Host "Collecting permissions from $vc..." -ForegroundColor Cyan

    $serverObj = Get-VIServer -Server $vc -ErrorAction Stop

    # Get all permissions from this vCenter
    $perms = Get-VIPermission -Server $serverObj

    foreach ($perm in $perms) {
        # Basic context
        $entity    = $perm.Entity
        $entityInv = Get-Inventory -Id $entity.Id -ErrorAction SilentlyContinue

        $entityName = $entityInv.Name
        $entityType = $entityInv.Type
        $entityPath = Get-InventoryPath -Object $entityInv

        $roleName   = $perm.Role
        $principal  = $perm.Principal
        $isGroup    = $perm.IsGroup
        $propagate  = $perm.Propagate

        if (-not $isGroup) {
            # Direct user permission
            $finalResults += [PSCustomObject]@{
                vCenter           = $serverObj.Name
                EntityName        = $entityName
                EntityType        = $entityType
                EntityPath        = $entityPath
                Role              = $roleName
                Principal         = $principal
                PrincipalIsGroup  = $false
                ResultantUser     = $principal
                SourceGroup       = $null
                Propagate         = $propagate
                PermissionType    = 'DirectUser'
            }
        }
        else {
            # Permission is assigned to a group; resolve group members
            $members = Resolve-ADGroupMembers -GroupName $principal -Recursive:$recursive -Domain $ADDomain

            if (-not $members -or $members.Count -eq 0) {
                # Could not resolve; still record the group itself
                $finalResults += [PSCustomObject]@{
                    vCenter           = $serverObj.Name
                    EntityName        = $entityName
                    EntityType        = $entityType
                    EntityPath        = $entityPath
                    Role              = $roleName
                    Principal         = $principal
                    PrincipalIsGroup  = $true
                    ResultantUser     = $null
                    SourceGroup       = $principal
                    Propagate         = $propagate
                    PermissionType    = 'Group-Unresolved'
                }
            }
            else {
                foreach ($user in $members) {
                    $finalResults += [PSCustomObject]@{
                        vCenter           = $serverObj.Name
                        EntityName        = $entityName
                        EntityType        = $entityType
                        EntityPath        = $entityPath
                        Role              = $roleName
                        Principal         = $principal
                        PrincipalIsGroup  = $true
                        ResultantUser     = $user
                        SourceGroup       = $principal
                        Propagate         = $propagate
                        PermissionType    = 'GroupDerived'
                    }
                }
            }
        }
    }
}

Write-Host "Total resultant permission rows: $($finalResults.Count)" -ForegroundColor Green

# Output
$finalResults |
    Sort-Object vCenter, ResultantUser, EntityPath, Role |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Export complete: $OutputPath" -ForegroundColor Green