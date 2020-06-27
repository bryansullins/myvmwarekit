<#
Author: Kevin Seales
Contributor: Bryan Sullins - bryansullins@thinkingoutcloud.org
Date: 6-26-2020
Version: 1.0
#>

# Setup vars and connection(s) to vCenter
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -confirm:$false
$vCenterList = Get-Content "vCenters/vCenterList.csv"
$Creds = Get-Credential

# Loop through all vCenters brought in from the CSV file and connect.
ForEach ($vCenter in $vCenterList) {

    Connect-VIServer -Server $vCenter -credential $Creds -WarningAction 0 -ErrorAction SilentlyContinue
    # Setup vars for use with Inventory - lines written to the inventory file and addtional vars for use in plays.
    $AllClusters = Get-Cluster | Sort-Object Name
    $VarsLine = "[all:vars]"
    $vCenterVar = "vcenter_hostname" + "=" + '"' + "$vCenter" + '"'
    $SiteTag = "site" + "=" + '"' + (Get-TagAssignment -Entity Datacenters | Select @{N='Site';E={$_.Tag.Name }}).Site + '"'
    # Sets Inventory Filename for all found Hosts
    $inventory_filename = "inventory/$vCenter"

    # Removes old inventory files
    Remove-Item $inventory_filename -ErrorAction SilentlyContinue
    # New line for separating Clusters:
    $NewLine = "`r"
    # Loop through hosts and add hosts to inventory files
    ForEach ($Cluster in $AllClusters) {
        $ClusterGroupName = "["+$Cluster.Name+"]" -replace '\s','' # -replace gets rid of spaces in Cluster names.
        Out-File -Append -FilePath $inventory_filename -InputObject $ClusterGroupName -Encoding ASCII
        $AllHostsinCluster = Get-Cluster -Name "$Cluster" | Get-VMHost | Sort-Object Name
        ForEach ($h in $AllHostsinCluster) {
            Out-File -Append -FilePath $inventory_filename -InputObject $h.Name -Encoding ASCII
        }
        Out-File -Append -FilePath $inventory_filename -InputObject $NewLine -Encoding ASCII
   }
   Out-File -Append -FilePath $inventory_filename -InputObject $VarsLine -Encoding ASCII
   Out-File -Append -FilePath $inventory_filename -InputObject $vCenterVar -Encoding ASCII
   Out-File -Append -FilePath $inventory_filename -InputObject $SiteTag -Encoding ASCII
   Disconnect-VIServer -Server $vCenter -confirm:$false
}
