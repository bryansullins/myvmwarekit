# MY VMWARE Kit - Custom modules for use with vCenter/ESXi Host/VM Automation PowerCLI CMDLets

#### Connect-MYvCenters - MUST use a vCenters file. Included with this repo.
Function Connect-MYvCenters ([Parameter(Mandatory=$true)][string]$PathtovCentersFile) {
    <#
    .SYNOPSIS
    This will connect to vCenters that are in a CSV file.
    .DESCRIPTION
    Allows you to connect to "All MY vCenters specified in a csv file." Create a csv file with the vCenters by IP or FQDN to which you would like to connect.
    .EXAMPLE
    Connect-MYvCenters -PathtovCentersFile C:\Path\to\csvfile.csv
    #>

    Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false
    Set-PowerCLIConfiguration -DefaultVIServerMode Multiple
    $vCenters = Get-Content -Path $PathtovCentersFile
    $c = Get-Credential
    ForEach ($vc in $vCenters) {
        Connect-VIServer -Server $vc -credential $c -WarningAction 0 -ErrorAction SilentlyContinue
    }
}
#Region get_functions
## Host configuration Settings for verification:  
Function Get-MYFWSettingsSyslog ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Reports the Syslog firewall setting.
    .DESCRIPTION
    This command will tell you if the Syslog Firewall port and service is open for the host specified. This is meant to be a troubleshooting command since this service/port is required to be open for the syslog forwarding to work.
    .EXAMPLE
    Get-MYFWSettingsSyslog -ESXiHost [ESXIHOSTNAME]
    #>
    $ESXiHostESXCli = Get-ESXcli -VMHost $ESXiHost -V2
    $ESXiHostESXCli.network.firewall.ruleset.list.Invoke() | Where-Object {$_.Name -eq "syslog" }
}

#Currently getting duplicates for these, but it does report the NFS Volumes and Hosts:
Function Get-MYNFSShareInfo ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Reports the NFS Share info on the retail store ESXi Host(s)
    .DESCRIPTION
    This command will tell you the ESXi Host (VMHost), NFS (Host) by IP, (Share) Name, Volume Name 
    .LINK
    .EXAMPLE
    Get-MYFNFSSharInfo -ESXiHost [ESXIHOSTNAME]
    #>

    # Write-Host "Getting NFS Info for '$ESXiHost':"
    $HostforNFS = Get-VMHost -Name $ESXiHost
    $ESXiHostCLI = Get-ESXCli -VMHost $ESXiHost
    $ESXiHostCLI.storage.nfs.list() | Select-Object @{N="VMHost";E={$HostforNFS.Name}},Host,Share,VolumeName
}    
    
Function Get-MYHostConfiguration ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Reports on some common configuration items of the ESXiHost. 
    .DESCRIPTION
    This command will report the settings. If you are not using 3PAR, then you can ignore the output.
    .LINK
    .EXAMPLE
    Get-MYHostConfiguration -ESXiHost [ESXIHOSTNAME]
    #>

    # Write-Host -Foregroundcolor Yellow "Now analyzing '$ESXiHost':"
    $VMHostName = Get-VMHost -Name $ESXiHost
    
    $WelcomeMessage = Get-VMHost -Name $ESXiHost | Get-AdvancedSetting -Name Annotations.WelcomeMessage
    $LogHost = Get-VMHost -Name $ESXiHost | Get-AdvancedSetting -Name Syslog.global.logHost
    $Scratch = Get-VMHost -Name $ESXiHost | Get-AdvancedSetting -Name ScratchConfig.ConfiguredScratchLocation
    
    # NTP - Servers and Server Running?
    $NTPService = Get-VMHostService -VMHost $ESXiHost | Where-Object {$_.Key -match "ntpd"}
    $NTPServers = Get-VMHost -Name $ESXIHost | Get-VmHostNtpServer
        
    # Get Power Policy
    $view = (Get-VMHost $ESXiHost | Get-View)
    $PowerPolicy = Get-View $view.ConfigManager.PowerSystem
    $Policy = $PowerPolicy | Select-Object -ExpandProperty Info | Select-Object -ExpandProperty CurrentPolicy
    If ($Policy.Key -eq 1) {
        $Policy = "High Performance"
    } Else {
        $Policy = "Not Set"
    }
    
    # Get 3PAR Custom Rule (By Vendor):
    $ESXCLI = Get-EsxCli -VMHost $ESXiHost
    $3PARRule = $ESXCLI.storage.nmp.satp.rule.list() | Where-Object {$_.Vendor -match '3PARdata'}

    # Get ATS Setting:
    [bool]$ATSSetting = Get-VMHost $ESXiHost | Get-AdvancedSetting -Name VMFS3.UseATSForHBOnVMFS5 | Select-Object Value
    
    # Get PerennialReserved = Value:
    $Perennial = $ESXCLI.storage.core.device.list() | Select-Object Device,IsPerenniallyReserved

    $HostConfig = New-Object PSObject -Property @{            
        'VMHostName' = $VMHostName.Name
        'WelcomeMessage' = $WelcomeMessage.Value
        'LogHost' = $LogHost.Value
        'Scratch' = $Scratch.Value
        'NTPServiceRunning' = $NTPService.Running
        'NTPServers' = (@($NTPServers) -join ',')
        'PowerPolicy' = $Policy
        '3PARDataExists' = (@($3PARRule.Vendor) -join ',')
        'ATSisSet' = $ATSSetting
        'Device' = (@($Perennial.Device) -join ',')
        'PerenniallyReserved' = (@($Perennial.IsPerenniallyReserved) -join ',')    
    } 
    $HostConfig | Select-Object VMHostName,LogHost,Scratch,NTPServiceRunning,NTPServers,PowerPolicy,3PARDataExists,ATSisSet,Device,PerenniallyReserved,WelcomeMessage
}

Function Get-MYWWNs ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Gets both PWWNs and NWWNs and formats as a table.
    .DESCRIPTION
    Use this command to get WWNs for zoming information.
    .EXAMPLE
    #>
    Get-VMhost -Name $ESXiHost | Get-VMHostHBA -Type FibreChannel | Select-Object VMHost,Device,@{N="WWPN";E={"{0:X}" -f $_.PortWorldWideName}},@{N="WWNN";E={"{0:X}" -f $_.NodeWorldWideName}} | Sort-Object VMhost

}
    
Function Get-MYSyslogLogHost ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Gets the Syslog.global.logHost value for the host specified.
    .DESCRIPTION
    Use this command to get the current Syslog.global.logHost for host.
    .EXAMPLE
    Get-MYSyslogLogHost -ESXiHost [ESXIHOSTNAME]
    #>
    $LogHost = Get-VMHost -Name $ESXiHost | Get-AdvancedSetting -Name Syslog.global.logHost -ErrorAction SilentlyContinue
    $HostLog = New-Object PSObject -Property @{            
        LogHost = $LogHost.Value 
        ESXiHost = $ESXiHost
    }
    $HostLog | Select-Object ESXIHost,LogHost
}
    
Function Get-MYVMsandDatastores ([Parameter(Mandatory=$true)][string]$VM) {
    <#
    .SYNOPSIS
    Gets all datastores used by each VM. This command will also list the Host and Cluster the VM currently resides.
    .DESCRIPTION
    Use this command to report the current datastores used by a VM. 
    .EXAMPLE
    Get-MYVMsandDatastores -VM [VMNAME]
    #>
    $VMName = Get-VM -Name $VM
    $Cluster = Get-VM -Name $VM | Get-Cluster
    $DS = Get-VM -Name $VM | Get-Datastore
    

    $VMandDS = New-Object PSObject -Property @{            
        VMName = $VMName.Name
        Datastore = (@($DS.Name) -join ',') 
        Cluster = $Cluster.Name
        
    } 
    $VMandDS | Select-Object VMName,Cluster,Datastore

}
    
Function Get-MYPhysicalNICInfo ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Gets Physical NIC information on the ESXiHost. Works only for elxnet drivers currently.
    .DESCRIPTION
    Use this command to Look at the Physical NIC information of the Host.
    .EXAMPLE
    Get-MYPhysicalNICInfo -ESXiHost [ESXIHOSTNAME]
    (Gets information for all Physical NICS)

    .EXAMPLE
    Get-MYPhysicalNICInfo -ESXiHost [ESXIHOSTNAME] | Where-Object { $_.Name -eq "vmnic0" }
    To see information for just one Physical NIC:
    [ESXIHOSTNAME] :

    AdminStatus : Up
    Description : Broadcom Corporation NetXtreme BCM5719 Gigabit Ethernet
    Driver      : ntg3
    Duplex      : Full
    Link        : Up
    LinkStatus  : Up
    MACAddress  : 3c:a8:2a:1d:25:80
    MTU         : 1500
    Name        : vmnic0
    PCIDevice   : 0000:02:00.0
    Speed       : 1000
    #>
    $ESXCLI = Get-ESXCLi -VMHost $ESXiHost -V2
    Write-Host -ForegroundColor Yellow "$ESXiHost :"
    $ESXCLI.network.nic.list.Invoke()
    $ESXCLI.software.vib.list.Invoke() | Where-Object { $_.Name -eq "elxnet" }
    
}
    
Function Get-MYAllHardwareDriverInfo ([Parameter(Mandatory=$true)][string]$ESXiHost) {
        <#
    .SYNOPSIS
    This command will get all Device Driver info and versions for the specified ESXi Host.
    .DESCRIPTION
    Use this command to get all Device driver info for the specified host - lengthy output, but can be looped.
    .EXAMPLE
    Get-MYAllHardwareDriverInfo -ESXiHost [ESXIHOST]
    Device                                                DeviceClass Module   Version
    ------                                                ----------- ------   -------
    Xeon E7 v3/Xeon E5 v3/Core i7 PCI Express Root Port 1 PCI bridge  vmkernel Version Releasebuild-10884925
    C610/X99 series chipset USB xHCI Host Controller      USB contro… vmkusb   0.1-1vmw.650.2.75.10884925
    . . .
    #>
    $ESXCli = Get-EsxCli -VMHost $ESXiHost

    ForEach ($dev in $ESXCli.hardware.pci.list()) {
        If ($dev.ModuleName -ne 'None') {
        $ESXCli.system.module.get($dev.ModuleName) |
        Select-Object @{N='Device';E={$dev.DeviceName}},@{N='DeviceClass';E={$dev.DeviceClassName}},Module,Version
        } # If Endbrace
    } # ForEach Endbrace
} # Function Endbrace 
    
Function Get-MYBIOSInfo ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Gets BIOS information for the Host - HPE-tested.
    .DESCRIPTION
    Use this command to get the BIOS information installed on the Host. Currently formatted as a Table for output.
    .EXAMPLE
    Get-MYBIOSInfo -ESXiHost [ESXIHOST]
    Cluster                 HostName                  BiosVersion BiosReleaseDate     BiosFirmwareMajorRelease BiosFirmwareMinorRelease
    -------                 --------                  ----------- ---------------     ------------------------ ------------------------
    [CLUSTERNAME] [ESXIHOST] P89         5/21/18 12:00:00 AM                        2                       61
    #>
    $ESXiClusterDisplay = (Get-VMHost $ESXiHost).Parent.Name
    $FinalBIOS = (Get-VMHost $ESXiHost | Get-View).Hardware.BiosInfo
    $BIOSReport = New-Object PSObject -Property @{            
        Cluster = $ESXiClusterDisplay
        HostName = $ESXiHost
        BiosVersion = (@($FinalBIOS.BiosVersion) -join ',')
        BiosReleaseDate = (@($FinalBIOS.ReleaseDate) -join ',')
        iLOFirmwareMajorRelease = (@($FinalBIOS.FirmwareMajorRelease) -join ',')
        iLOFirmwareMinorRelease = (@($FinalBIOS.FirmwareMinorRelease) -join ',')
    } 
    $BIOSReport | Select-Object Cluster,HostName,BiosVersion,BiosReleaseDate,iLOFirmwareMajorRelease,iLOFirmwareMinorRelease
}
    
Function Get-MYDSPercentFree ([Parameter(Mandatory=$true)][string]$DS) {
        <#
    .SYNOPSIS
    Gets percent free for the datastore specified.
    .DESCRIPTION
    Use this command to get the space usage in percent free for the specified datastore.
    .EXAMPLE
    Get-MYDSPercentFree -DS [DATASTORENAME]

    Datastore   : [DATASTORENAME]
    ClusterName : [CLUSTERNAME]
    CapacityGB  : 749.75
    FreeSpace   : 330.06
    PercentFree : 44.02

    #>
    $Volume = Get-Datastore -Name $DS
    $ClusterName = $Volume | Get-DatastoreCluster
    $PercentFree = ($Volume.FreeSpaceGB / $Volume.CapacityGB)
    $PercentFreeNonRounded = ($PercentFree * 100)
    $PercentFree = [math]::Round($PercentFreeNonRounded,2)
    $PercentFreeReport = New-Object PSObject -Property @{
        Datastore = $DS
        ClusterName = $Clustername.Name
        StorageCluster = $Volume.Parent
        CapacityGB = [math]::Round($Volume.CapacityGB,2)
        FreeSpace = [math]::Round($Volume.FreeSpaceGB,2)
        PercentFree = $PercentFree
    }
    $PercentFreeReport | Select-Object Datastore,ClusterName,CapacityGB,FreeSpace,PercentFree
}
    
Function Get-MYCPURatio ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Gets the ratio of physical cores to used vCPUs by VMs on the host and does the math.
    .DESCRIPTION
    Use this command to get the vCPU Ratio on the host. VMWare best practice is that the ratio should not be higher than 4:1.
    .EXAMPLE
    Get-MYCPURatio -ESXiHost [ESXIHOSTNAME]

    Name                 : [ESXIHOSTNAME]
    pCPU cores available : 20
    vCPU assigned to VMs : 22
    Ratio                : 1.1
    CPU Overcommit (%)   : 10

    #>
    $ESXiHostInfo = Get-VMHost $ESXiHost  
    $vCPU = Get-VM -Location $ESXiHost | Measure-Object -Property NumCpu -Sum | Select-Object -ExpandProperty Sum  
    $ESXiHostInfo | Select-Object Name,  
    @{N='pCPU cores available';E={$_.NumCpu}},  
        @{N='vCPU assigned to VMs';E={$vCPU}},  
        @{N='Ratio';E={[math]::Round($vCPU/$_.NumCpu,1)}},  
    @{N='CPU Overcommit (%)';E={[Math]::Round(100*(($vCPU - $_.NumCpu) / $_.NumCpu), 1)}}  
}  
    
Function Get-MYCPUCount ([Parameter(Mandatory=$true)][string]$ESXIHost) {
        <#
    .SYNOPSIS
    Gets the number of physical cores on the Host.
    .DESCRIPTION
    Use this command to get the number of physical cores on the host.
    .EXAMPLE
    Get-MYCPUCount -ESXiHost [ESXIHOSTNAME]

    Cluster                 HostName                  CPUSocket CoresPerSocket
    -------                 --------                  --------- --------------
    [CLUSTERNAME] [ESXIHOSTNAME]         2             10

    #>
    $result = @()
    $vmhost = get-vmhost -Name $ESXIHost

foreach ($esxi in $vmhost) {
    $HostCPU = $esxi.ExtensionData.Summary.Hardware.NumCpuPkgs
    $HostCPUcore = $esxi.ExtensionData.Summary.Hardware.NumCpuCores/$HostCPU
    $obj = new-object psobject
    $obj | Add-Member -MemberType NoteProperty -Name Cluster -Value $esxi.Parent
    $obj | Add-Member -MemberType NoteProperty -Name HostName -Value $esxi.Name
    $obj | Add-Member -MemberType NoteProperty -Name CPUSocket -Value $HostCPU
    $obj | Add-Member -MemberType NoteProperty -Name CoresPerSocket -Value $HostCPUcore
    $result += $obj

    }
$result
}
    
Function Get-MYNumberofVMsPerHost ([Parameter(Mandatory=$true)][string]$ESXiHost) {
        <#
    .SYNOPSIS
    Gets the nukber of Powered On VMS on a host.
    .DESCRIPTION
    Use this command to see number of VMs on a host. This can be useful for some math, including licensing.
    .EXAMPLE
    #>
    Get-VMHost -Name $ESXiHost | Select @{N="Cluster";E={Get-Cluster -VMHost $_}},Name,@{N="NumVM";E={($_ |Get-VM | where {$_.PowerState -eq "PoweredOn"}).Count}}
}
    
Function Get-MYvRAMOvercommit ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Gets the Value of RAM and reports RAM Overcommitment value.
    .DESCRIPTION
    Use this command to compute RAM Overcommitted.
    .EXAMPLE
    Get-MYvRAMRatio -ESXiHost [ESXIHOSTNAME]

    Name                           Value
    ----                           -----
    ESXi Host                      [ESXIHOSTNAME]
    Physical RAM (GB)              127.87
    Total vRAM (GB)                72
    PoweredOn vRAM (GB)            72
    vRAM/Physical RAM ratio        0.563
    RAM Overcommit (%)             -43.69

    #>
    $VARESXi = Get-VMHost -Name $ESXiHost
    $PhysRAM = [Math]::Round($VARESXi.MemoryTotalGB, 2)
    $HostPoweredOnvRAM = [Math]::Round((Get-VM -Location $VARESXi | Where-Object {$_.PowerState -eq "PoweredOn" } | Measure-Object MemoryGB -Sum).Sum, 2)

    # Building the properties for our custom object
    $OvercommitInfoProperties = New-Object PSObject -Property @{
        'ESXiHost'=$VARESXi.Name                    
        'PhysicalRAMinGB'=$PhysRAM
        'TotalvRAMinGB'=[Math]::Round((Get-VM -Location $VERESXi | Measure-Object MemoryGB -Sum).Sum, 2)
        'PoweredOnvRAMinGB'=if ($HostPoweredOnvRAM) {$HostPoweredOnvRAM} Else { 0 -as [int] }
        'vRAM/PhysicalRAMRatio'=if ($HostPoweredOnvRAM) {[Math]::Round(($HostPoweredOnvRAM / $PhysRAM), 3)} Else { $null }
        'RAMOvercommitPercentage'=if ($HostPoweredOnvRAM) {[Math]::Round(100*(($HostPoweredOnvRAM - $PhysRAM) / $PhysRAM), 2)} Else { $null }
        }           

        $OvercommitInfoProperties | Select-Object ESXiHost,PhysicalRAMinGB,TotalvRAMinGB,PoweredOnvRAMinGB,vRAM/PhysicalRAMRatio,RAMOvercommitPercentage
}
    
Function Get-MYHostManagementInfo ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Short command to get ESXi Host, vCenter, Cluster, and management IP address.
    .DESCRIPTION
    This command will get the vCenter, Cluster and ESXi Host and any IP addresses for that host. A request for this kept coming up so I made it part of the toolkit. I have used this quite a bit.
    .EXAMPLE
    Get-MYHostManagementInfo -ESXiHost [ESXIHOSTNAME]
    #>
    $Hostname = Get-VMHost -Name $ESXiHost
    $HostConnectionState = $ESXiHost.ConnectionState
    $HostView = Get-VMhost -Name $ESXiHost | Get-View
    $HostvCenterIP = $HostView.Summary.ManagementServerIP
    $HostvCenterHostName = [System.Net.Dns]::GetHostEntry($HostvCenterIP).HostName
    $IP = Get-VMHost -Name $ESXiHost | Get-VMHostNetworkAdapter -Name vmk0 | Select-Object -ExpandProperty IP
    $Model = $Hostname.Model
    $HostandIP = New-Object PSObject -Property @{            
        'vCenter' = $HostvCenterHostName
        'MemberofCluster' = $Hostname.Parent
        'VMHostName' = $Hostname.Name
        'IPAddress' = $IP
        'Model' = $Model
        } 
    $HostandIP | Select-Object vCenter,MemberofCluster,VMHostName,IPAddress,Model
}
    
Function Get-MYvSwitchSecPolicy ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Report all vSwitches and their security policies. This command will additionally report what VMs are attached to each vSwitch.
    .DESCRIPTION
    This command reports all vSwitches on a Host, its security policies and what VMs are attached to each vSwitch. The usefulness of this is going to depend on which VMNICs you are using.
    .LINK
    .EXAMPLE
    Get-MYvSwitchSecPolicy -ESXiHost [ESXIHOSTNAME]

    ESXiHostName     : [ESXIHOSTNAME]
    vSwitch          : vSwitch0
    AllowPromiscuous : False
    ForgedTransmits  : True
    MacChanges       : True
    VMsAttached      : vSphere Management Assistant
    #>
    
    $AllvSwitches = Get-VMHost -Name $ESXiHost | Get-VirtualSwitch | Sort-Object Name
    ForEach ($s in $AllvSwitches) {
        $SecurityPolicy = Get-VMHost -Name $ESXiHost | Get-VirtualSwitch -Name "$s" | Get-SecurityPolicy
        $VMsAttached = Get-VMHost -Name $ESXiHost | Get-VirtualSwitch -Name "$s" | Get-VM
        
        $SecPolicyReport = New-Object PSObject -Property @{            
            'ESXiHostName' = $ESXiHost
            'vSwitch' = $s.Name
            'AllowPromiscuous' = $SecurityPolicy.AllowPromiscuous
            'ForgedTransmits' = $SecurityPolicy.ForgedTransmits
            'MacChanges' = $SecurityPolicy.MacChanges
            'VMsAttached' = (@($VMsAttached.Name) -join ',')
            } 
        $SecPolicyReport | Select-Object ESXiHostName,vSwitch,AllowPromiscuous,ForgedTransmits,MacChanges,VMsAttached
    }
    
}
    
Function Get-MYCiscoDiscoveryInfo ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Reports all CDP Info for each physical NIC
    .DESCRIPTION
    This command reports information you would get from the info icon next to each switch.
    .LINK
    .EXAMPLE
    #>
    Get-VMHost -Name $ESXiHost | Where-Object {$_.ConnectionState -eq "Connected"} | %{Get-View $_.ID} |
    %{$esxname = $_.Name; Get-View $_.ConfigManager.NetworkSystem} |
    %{ foreach($physnic in $_.NetworkInfo.Pnic){
        $pnicInfo = $_.QueryNetworkHint($physnic.Device)
            foreach($hint in $pnicInfo){
                Write-Host $esxname $physnic.Device
                if( $hint.ConnectedSwitchPort ) {
                $hint.ConnectedSwitchPort
                }
                else {
                    Write-Host "No CDP information available."; Write-Host
                }
            }
        }
    } 
}
    
Function Get-MYCDandDVD ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    This command finds VMs with anything attached to the CD/DVD.
    .DESCRIPTION
    This command looks for anything attached to the CD/DVD, but does not detach it. To detach, use the Set-MYDisconnectCD command.
    .LINK
    .EXAMPLE
    
    #>
    Get-VMHost -Name $ESXiHost | Get-VM | Where-Object { $_ | get-cddrive | where { $_.ConnectionState.Connected -eq "true"}}
}

Function Get-MYVIEventPlus {
<#   
.SYNOPSIS  Returns vSphere events    
.DESCRIPTION The function will return vSphere events. With
    the available parameters, the execution time can be
    improved, compered to the original Get-VIEvent cmdlet. 
.NOTES  Author:  Luc Dekens   
.PARAMETER Entity
    When specified the function returns events for the
    specific vSphere entity. By default events for all
    vSphere entities are returned. 
.PARAMETER EventType
    This parameter limits the returned events to those
    specified on this parameter. 
.PARAMETER Start
    The start date of the events to retrieve 
.PARAMETER Finish
    The end date of the events to retrieve. 
.PARAMETER Recurse
    A switch indicating if the events for the children of
    the Entity will also be returned 
.PARAMETER User
    The list of usernames for which events will be returned 
.PARAMETER System
    A switch that allows the selection of all system events. 
.PARAMETER ScheduledTask
    The name of a scheduled task for which the events
    will be returned 
.PARAMETER FullMessage
    A switch indicating if the full message shall be compiled.
    This switch can improve the execution speed if the full
    message is not needed.   
.EXAMPLE
    PS> Get-VIEventPlus -Entity $vm
.EXAMPLE
    PS> Get-VIEventPlus -Entity $cluster -Recurse:$true
#>
    
param(
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$Entity,
    [string[]]$EventType,
    [DateTime]$Start,
    [DateTime]$Finish = (Get-Date),
    [switch]$Recurse,
    [string[]]$User,
    [Switch]$System,
    [string]$ScheduledTask,
    [switch]$FullMessage = $false
    )
    
    process {
    $eventnumber = 100
    $events = @()
    $eventMgr = Get-View EventManager
    $eventFilter = New-Object VMware.Vim.EventFilterSpec
    $eventFilter.disableFullMessage = ! $FullMessage
    $eventFilter.entity = New-Object VMware.Vim.EventFilterSpecByEntity
    $eventFilter.entity.recursion = &{if($Recurse){"all"}else{"self"}}
    $eventFilter.eventTypeId = $EventType
    if($Start -or $Finish){
        $eventFilter.time = New-Object VMware.Vim.EventFilterSpecByTime
    if($Start){
        $eventFilter.time.beginTime = $Start
    }
    if($Finish){
        $eventFilter.time.endTime = $Finish
    }
    }
    if($User -or $System){
    $eventFilter.UserName = New-Object VMware.Vim.EventFilterSpecByUsername
    if($User){
        $eventFilter.UserName.userList = $User
    }
    if($System){
        $eventFilter.UserName.systemUser = $System
    }
    }
    if($ScheduledTask){
    $si = Get-View ServiceInstance
    $schTskMgr = Get-View $si.Content.ScheduledTaskManager
    $eventFilter.ScheduledTask = Get-View $schTskMgr.ScheduledTask |
        where {$_.Info.Name -match $ScheduledTask} |
        Select -First 1 |
        Select -ExpandProperty MoRef
    }
    if(!$Entity){
    $Entity = @(Get-Folder -Name Datacenters)
    }
    $entity | %{
        $eventFilter.entity.entity = $_.ExtensionData.MoRef
        $eventCollector = Get-View ($eventMgr.CreateCollectorForEvents($eventFilter))
        $eventsBuffer = $eventCollector.ReadNextEvents($eventnumber)
        while($eventsBuffer){
        $events += $eventsBuffer
        $eventsBuffer = $eventCollector.ReadNextEvents($eventnumber)
        }
        $eventCollector.DestroyCollector()
    }
    $events
    }
}

Function Move-MYVMOffCurrHost ([Parameter(Mandatory=$true)][string]$VMName) {
    <#
    .SYNOPSIS
    Move the VM off the current host to any other host in the cluster.
    .DESCRIPTION
    This command will move the VM off the current host and place it on a random host elsewhere in the same cluster. This can be used for vMotion testing or troubleshooting. The command output will give progress percentage as the VM is moved and will tell you to which host the VM has been moved.
    .EXAMPLE
    Move-MyVMOffCurrHost -VMName [VMName]
    #>

    # Set up vars for this function - "find" the VM and footprint the cluster
    $VMToMove = Get-VM -Name $VMName
    $AllHostsinCluster = Get-VM -Name $VMName | Get-Cluster | Get-VMHost | Sort-Object Name
    $CurrHost = $VMToMove | Get-VMHost
    # Choose a random host in the cluster that isn't the VM's current Host
        Do {
            $NewHostRefNum = Get-Random -Maximum ($AllHostsinCluster.count - 1)
        } While ($CurrHost -match $AllHostsinCluster[$NewHostRefNum])
    # Move VM to new host and print the result:
    $NewHosttoMoveTo = $AllHostsinCluster[$NewHostRefNum]
    Move-VM -VM $VMToMove -Destination $NewHosttoMoveTo
    Write-Host -Foregroundcolor Magenta "$VMName is now on host $NewHosttoMoveTo."
}

Function Get-MYvMotionHistory {
<#   
.SYNOPSIS  Returns the vMotion/svMotion history    
.DESCRIPTION The function will return information on all
    the vMotions and svMotions that occurred over a specific
    interval for a defined number of virtual machines 
.NOTES  Author:  Luc Dekens   
.PARAMETER Entity
    The vSphere entity. This can be one more virtual machines,
    or it can be a vSphere container. If the parameter is a
    container, the function will return the history for all the
    virtual machines in that container. 
.PARAMETER Days
    An integer that indicates over how many days in the past
    the function should report on. 
.PARAMETER Hours
    An integer that indicates over how many hours in the past
    the function should report on. 
.PARAMETER Minutes
    An integer that indicates over how many minutes in the past
    the function should report on. 
.PARAMETER Sort
    An switch that indicates if the results should be returned
    in chronological order. 
.EXAMPLE
    PS> Get-MotionHistory -Entity $vm -Days 1
.EXAMPLE
    PS> Get-MotionHistory -Entity $cluster -Sort:$false
.EXAMPLE
    PS> Get-Datacenter -Name $dcName |
    >> Get-MotionHistory -Days 7 -Sort:$false
#>
    
    param(
    [CmdletBinding(DefaultParameterSetName="Days")]
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$Entity,
    [Parameter(ParameterSetName='Days')]
    [int]$Days = 1,
    [Parameter(ParameterSetName='Hours')]
    [int]$Hours,
    [Parameter(ParameterSetName='Minutes')]
    [int]$Minutes,
    [switch]$Recurse = $false,
    [switch]$Sort = $true
    )
    
    begin{
    $history = @()
    switch($psCmdlet.ParameterSetName){
        'Days' {
        $start = (Get-Date).AddDays(- $Days)
        }
        'Hours' {
        $start = (Get-Date).AddHours(- $Hours)
        }
        'Minutes' {
        $start = (Get-Date).AddMinutes(- $Minutes)
        }
    }
    $eventTypes = "DrsVmMigratedEvent","VmMigratedEvent"
    }
    
    process{
    $history += Get-MYVIEventPlus -Entity $entity -Start $start -EventType $eventTypes -Recurse:$Recurse |
    Select CreatedTime,
    @{N="Type";E={
        if($_.SourceDatastore.Name -eq $_.Ds.Name){"vMotion"}else{"svMotion"}}},
    @{N="UserName";E={if($_.UserName){$_.UserName}else{"System"}}},
    @{N="VM";E={$_.VM.Name}},
    @{N="SrcVMHost";E={$_.SourceHost.Name.Split('.')[0]}},
    @{N="TgtVMHost";E={if($_.Host.Name -ne $_.SourceHost.Name){$_.Host.Name.Split('.')[0]}}},
    @{N="SrcDatastore";E={$_.SourceDatastore.Name}},
    @{N="TgtDatastore";E={if($_.Ds.Name -ne $_.SourceDatastore.Name){$_.Ds.Name}}}
    }
    
    end{
    if($Sort){
        $history | Sort-Object -Property CreatedTime
    }
    else{
        $history
    }
    }
}
#EndRegion get_functions
#Region set_functions

Function Set-MYScratch ([Parameter(Mandatory=$true)][string]$ESXiHost,[Parameter(Mandatory=$true)][string]$ScratchDatastore,[Parameter(Mandatory=$true)][string]$ScratchDirUUIDPath) {
    <#
    .SYNOPSIS
    Set the scratch partition for the given host.
    
    .DESCRIPTION
    Currently all the Parameters must be set by the user. They include:

    ESXiHost - ESXi Host by vCenter inventory name. 
    ScratchDatastore - Scratch datastore name. 
    ScratchDirUUIDPath - Scratch datastore local path.

    Usually the scratch datastore is the same for all hosts in the cluster, so this command, like most (all?) others in the toolkit is ForEach loop-able.

    .EXAMPLE
    #>
 
    $Datastore = Get-Datastore $ScratchDatastore
    New-PSDrive -Location $Datastore -Name DS -PSProvider VimDatastore -Root '\'
    New-Item -Path DS:\.locker-$ESXiHost -ItemType Directory
    Get-VMHost -Name $ESXiHost | Get-AdvancedSetting -Name ScratchConfig.ConfiguredScratchLocation | Set-AdvancedSetting -Value $ScratchDirUUIDPath/.locker-$ESXiHost -Confirm:$false
    Remove-PSDrive -Name DS -Confirm:$false
}

Function Set-MYSyslogValue ([Parameter(Mandatory=$true)][string]$ESXiHost,[Parameter(Mandatory=$true)][string]$LogHostValue) {
    <#
    .SYNOPSIS
    Set the sysloghost value to the desired value for the indicated ESXi host.
    .DESCRIPTION
    You will need to enter in the ESXi Host to configure and the LogHostValue (Syslog.global.logHost in ESXi Advanced Settings) you want for the host. It is recommended to enter the LogHostValue in quotes. 
    .EXAMPLE
    Set-MYSyslogValue -ESXiHost [ESXiHOSTFQDN] -LogHostValue "[LOGHOSTVALUE]"
    #>

    [string]$CurrSetting = Get-VMHost -Name $ESXiHost | Get-AdvancedSetting -Name Syslog.global.logHost | Select-Object Value
    $ProperValue = $LogHostValue
    If ($CurrSetting -match $LogHostValue) {
        Write-Host -ForegroundColor Green "$ESXiHost is already set to '$ProperValue'"
    }
    Else {
        Write-Host -ForegroundColor Red "$ESXiHost is not set to $ProperValue - setting now."
        Get-VMHost -Name $ESXiHost | Get-AdvancedSetting -Name Syslog.global.logHost | Set-AdvancedSetting -Value $LogHostValue -Confirm:$false
        Write-Host -ForegroundColor Magenta "Setting $ESXiHost firewall to open SYSLOG port . . ."
        $SyslogFirewallExceptions = Get-VMHostFirewallException -VMHost $ESXiHost | Where-Object {$_.Name.StartsWith('syslog')}
        $SyslogFirewallExceptions | Set-VMHostFirewallException -Enabled $true
        # Verify the setting was put into effect:
        $ESXiHostESXCli = Get-ESXcli -VMHost $ESXiHost -V2
        $ESXiHostESXCli.network.firewall.ruleset.list.Invoke() | Where-Object {$_.Name -eq "syslog" }
    }

}

Function Set-MYSYSLOGGlobalDir ([Parameter(Mandatory=$true)][string]$ESXiHost,[Parameter(Mandatory=$true)][string]$LogDatastore) {
    <#
    .SYNOPSIS
    Set the Syslog global directory for the specified host.    
    .DESCRIPTION
    This command will set the Syslog.global.logDir value in the Advanced settings. You will need to specify the Host and the Datastore by name.
    .EXAMPLE
    Set-MYSYSLOGGlobalDir -ESXiHost [ESXiHOSTFQDN] -LogDatastore vpux_lvbhp01-000
    #>
    Get-VMHost -Name $ESXiHost | Get-AdvancedSetting -Name Syslog.global.logDir | Set-AdvancedSetting -Value [$LogDatastore]/log -Confirm:$false
}

Function Set-MYRRDefault ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Set the default Storage policy (VMware multipathing) to Round Robin.    
    .DESCRIPTION
    Use this command to set the default Storage policy (VMware multipathing) to Round Robin. This command simply sets the default policy to Round Robin. To set the current datastores, you will need to use different means which are not currently part of the MY PowerCLI toolkit.
    .EXAMPLE
    Set-MYRRDefault -ESXiHost [ESXiHOSTFQDN]
    #>
    
    $defaultpsp = "VMW_PSP_RR"
    $satp = "VMW_SATP_DEFAULT_AA"
    Write-Host "Setting Default PSP to $defaultpsp for SATP $satp on $ESXiHost" -ForegroundColor green
    $esxcli = Get-EsxCli -VMHost $ESXiHost -V2
    $esxcli.storage.nmp.satp.set($null,$defaultpsp,$satp)

}

Function Set-MYFWAllowSyslog ([Parameter(Mandatory=$true)][string]$ESXiHost) {

    <# 
    .SYNOPSIS
    Open up the firewall rule for outgoing Syslog.
    .DESCRIPTION
    This command allows outgoing syslog connections over port 514. This is a standalone command that will leave the Syslog settings untouched, but will open the proper port only. 
    .LINK
    See "Related Information" in the VMWare KB Article: https://kb.vmware.com/s/article/2003322
    .EXAMPLE
    Set-MYFWAllowSyslog -ESXiHost [ESXiHOSTFQDN]
    #>

    # Open syslog port 514 Outgoing. 
    $SyslogFirewallExceptions = Get-VMHostFirewallException -VMHost $ESXiHost | Where-Object {$_.Name.StartsWith('syslog')}
    $SyslogFirewallExceptions | Set-VMHostFirewallException -Enabled $true
    # Verify the setting was put into effect:
    $ESXiHostESXCli = Get-ESXcli -VMHost $ESXiHost -V2
    $ESXiHostESXCli.network.firewall.ruleset.list.Invoke() | Where-Object {$_.Name -eq "syslog" }

}

Function Start-MYSSH ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Simple command to start SSH on the given Host.
    .DESCRIPTION
    This command starts SSH on the given host. This command does not set the SSH service to start with the host.
    .EXAMPLE
    Start-MYSSH -ESXiHost [ESXiHOSTFQDN]
    #>
    
    Get-VMHostService -VMHost $ESXiHost | Where-Object {$_.Key -eq "TSM-SSH"} | Start-VMHostService -Confirm:$false
}

Function Stop-MYSSH ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Simple command to stop SSH on the given Host.
    .DESCRIPTION
    This command stops SSH on the given host. This command does not set the SSH service to start with the host.
    .EXAMPLE
    Stop-MYSSH -ESXiHost [ESXiHOSTFQDN]
    #>
    Get-VMHostService -VMHost $ESXiHost | Where-Object {$_.Key -eq "TSM-SSH"} | Stop-VMHostService -Confirm:$false
}

Function Set-MYPowerPolicyHigh ([Parameter(Mandatory=$true)][string]$ESXiHost) {
    <#
    .SYNOPSIS
    Change the Power Policy to High on the specified ESXi host.
    .DESCRIPTION
    This command changes the Power Policy to "High" on the ESXi host.
    .EXAMPLE
    Set-MYPowerPolicyHigh -ESXiHost [ESXiHOSTFQDN]
    #>

    $ESXiHostView = (Get-VMHost $ESXiHost | Get-View)
    (Get-View $ESXiHostView.ConfigManager.PowerSystem).ConfigurePowerPolicy(1)
}

Function Set-MYDisconnectCD ([Parameter(Mandatory=$true)][string]$Cluster) {
    <#
    .SYNOPSIS
    Detect if the CD/DVD is connected and if so, will set to Client Device.
    .DESCRIPTION
    This command will detect if there is a CD/DVD device connected of any type (including Content Library) and if there is a cd/DVD connected, it will set it to "Client Device". If there is nothing connected, the command will do nothing.
    
    NOTE: Based on request, this command will do this for every VM in the specified Cluster. If you want to do this on one VM (or ForEach through a defined list, use the Set-MYDisconnectCDSingleVM MY Toolkit command)

    .EXAMPLE    
    #>

    $VMsinCluster = Get-Cluster -Name "$Cluster" | Get-VM
    ForEach ($v in $VMsinCluster) {
    $CDDriveConnected = Get-VM -Name $v | Where-Object { $_ | get-cddrive | Where-Object { $_.ConnectionState.Connected -eq "true" } } | Sort-Object Name
    $VMPowerState = Get-VM -Name $v | Select-Object PowerState
    If ($CDDriveConnected -eq $null -Or $VMPowerState -eq "PoweredOff") {
        Write-Host "$v - No CD/DVDs connected or is Powered Off - nothing to do."
    } Else {
            Write-Host -ForegroundColor Magenta "Disconnecting CD/DVD from $v"
            Get-VM -Name $v | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false | Out-Null
        }
    }    
}

Function Set-MYDisconnectCDSingleVM ([Parameter(Mandatory=$true)][string]$VMName) {
    <#
    .SYNOPSIS
    Detect if the CD/DVD is connected to a single VM, and if so, will set to Client Device.
    .DESCRIPTION
    This command will detect if there is a CD/DVD device connected of any type (including Content Library) and if there is a CD/DVD connected, it will set it to "Client Device". If there is nothing connected, the command will do nothing. This command, like most others can be looped to perform this action across multiple VMs of your defined choice.

    .EXAMPLE
    
    #>
    $CDDriveConnected = Get-VM -Name $VMName | Where-Object { $_ | get-cddrive | Where-Object { $_.ConnectionState.Connected -eq "true" } } | Sort-Object Name
    $VMPowerState = Get-VM -Name $VMName | Select-Object PowerState
    If ($CDDriveConnected -eq $null -Or $VMPowerState -eq "PoweredOff") {
        Write-Host "$VMName - No CD/DVDs connected or is Powered Off - nothing to do."
    } Else {
            Write-Host -ForegroundColor Magenta "Disconnecting CD/DVD from $VMName"
            Get-VM -Name $VMName | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false | Out-Null
        }
}

Function Set-MYTaggedVMtoPartial ([Parameter(Mandatory=$true)][string]$ClusterName,[Parameter(Mandatory=$true)][string]$Tagname) {
    <#
    .SYNOPSIS
    Sets the VMs tagged with the Tagname parameter in the Specified Cluster to "Partially Automated".
    .DESCRIPTION
    This command will set any VMs in the specified cluster with the specified tag name to "DRS Partially Automated" as an Override. This was built as a result of the Docker recommendation in the Link section here in the Help for this Command. 
    .LINK
    https://success.docker.com/article/vmware-common-issues-when-running-docker-ee
    .EXAMPLE
    Set-MYTaggedVMtoPartial -ClusterName "LVB  Tier0 Mgmt Cluster" -Tagname "Docker"                                                                 
    #>
    $TaggedVMs = Get-Cluster -Name $ClusterName | Get-VM | where {(Get-TagAssignment -Entity $_ | Select -ExpandProperty Tag) -match "$Tagname" }
    ForEach ($tvm in $TaggedVMs) {
        Set-VM -VM $tvm -DrsAutomationLevel PartiallyAutomated -confirm:$False
    }
    # Get-VM | where {(Get-TagAssignment -Entity $_ | Select -ExpandProperty Tag) -like 'Backups*'}
}

Function Set-MYChangeESXiPassword ([string]$ESXiHost, $RootCredential, $NewRootCredential) {
    <#
    .SYNOPSIS 
    Change the root password of an ESXi host to the desired new root password.
    .DESCRIPTION
    Use this command to change the root password of an ESXi host. Current and new password credentials can now be passed in as a variable using the -RootCredential and -NewRootCredential switch
    .EXAMPLE
    Set-MYChangeESXiPassword -ESXiHost [ESXiNODEFQDN]
    #>
    
    #Setup runtime approach:
    $ErrorActionPreference = "Stop"

    Write-Host "Press Ctrl+c at any time to quit the command - re-run the command to start again."
    
    if ($RootCredential -eq $null) {
    [System.Security.SecureString]$RootPassword         = Read-Host -Prompt "Enter current root password for $ESXiHost" -AsSecureString
    $RootCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$RootPassword
	}
    else { }
    if ($NewRootCredential -eq $null) {
    [System.Security.SecureString]$NewPassword          = Read-Host -Prompt "Enter new root password" -AsSecureString
    [System.Security.SecureString]$NewPasswordVerify    = Read-Host -Prompt "Re-enter new root password" -AsSecureString
    $NewRootCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$NewPassword
    $NewRootCredentialVerify = new-object -typename System.Management.Automation.PSCredential -argumentlist "root",$NewPasswordVerify    
    If(($NewRootCredential.GetNetworkCredential().Password) -ne ($NewRootCredentialVerify.GetNetworkCredential().Password)) {
        throw "Passwords do not match!!!"
    }
    
    }
    else {}
    # Setup additional parameters for this Function
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null


    # Create an object for the root account with the new password
    $RootAccount = New-Object VMware.Vim.HostPosixAccountSpec
    $RootAccount.id = "root"
    $RootAccount.password = ($NewRootCredential.GetNetworkCredential().Password)
    $RootAccount.shellAccess = "/bin/bash"
    
    # If the script gets this far, now change the password:
    # Disconnect any connected ESXi Sessions, but keep the vCenter session(s) open.
    $VIConnections = $global:DefaultVIServers
    ForEach ($conn in $VIConnections) {
        If ($conn.User -eq "root") {
            $ESXiConn = $conn.Name
            Write-Host -Foregroundcolor Magenta "Disconnecting from $ESXiConn as a cleanup measure."
            Disconnect-VIServer -Server $conn.Name -Confirm:$False -ErrorAction SilentlyContinue
        } ElseIf ($conn.User -ne "root") {
            $vCenterConn = $conn.Name
            Write-Host -Foregroundcolor Magenta "Staying connected to vCenter connection $vCenterConn."
        } Else {
            Write-Host -Foregroundcolor Magenta "No other vCenter or ESXi host connections detected. Continuing to password change."
        }
    }

    Write-Host -Foregroundcolor Magenta "Attempting to connect to $ESXiHost."
    # Create a direct connection to the host
    $VIServer = Connect-VIServer -Server $ESXiHost -User "root" -Password ($RootCredential.GetNetworkCredential().Password) -ErrorAction SilentlyContinue
    # If it's connected, change the password.
    If($VIServer.IsConnected -eq $True) {
        $VMHost = (Get-VMHost -Name $ESXiHost).Name
        Write-Host -Foregroundcolor Magenta ("Connected to " + $VMHost)
        # Attempt to update the Root user object and catch any errors in a try/catch block to log any failures.
        Try {
            $ServiceInstance = Get-View ServiceInstance
            $AccountManager = Get-View -Id $ServiceInstance.content.accountManager 
            $AccountManager.UpdateUser($RootAccount)
            Write-Host -Foregroundcolor Magenta ("Password changed on " + $VMHost)
        }
        Catch {
            Write-Host -Foregroundcolor Magenta ("Password change failed on " + $VMHost)
            }
    } Else {
        Write-Host -Foregroundcolor Magenta ("Unable to connect to $ESXiHost. Please check password or network connection.")
    }

}

Function Set-MYDisableAdmissionControl ([Parameter(Mandatory=$true)][string]$ClusterName) {
    <#
    .SYNOPSIS
    Disables Admission Contol on the specified Cluster.
    .DESCRIPTION
    .EXAMPLE
    #>
    $AdmCtlStatus = Get-Cluster -Name $ClusterName | Select-Object HAAdmissionControlEnabled
    If ($AdmCtlStatus -match "True") {
        Set-Cluster -Cluster $ClusterName -HAAdmissionControlEnabled $False -Confirm:$False
    } # End AdmCtrlStatus If Statement
} # End Set-MYDisableAdmissionControl Function

## Experimental: ################################################################################################
## Section here for experimental Functions.