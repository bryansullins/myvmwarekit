#################################################
#  Script Name: PS_HPE_iLo_Config.ps1
#
#  Supported Hardware: iLO4, iLO5
#
#  This Standalone Script is used to get check the iLO configuration and 
#  update the configuration as needed
#  https://www.hpe.com/us/en/product-catalog/detail/pip.5440657.html
#  Download Link
#  https://support.hpe.com/hpsc/swd/public/detail?sp4ts.oid=1008862655&swItemId=MTX_2596ebfd0d404421be2ea73ca4&swEnvOid=4184
#
#  Prerequisites:
#  Install iLO powershell Modules from UNC above
#  Must have an OS installed and configured on the Serve so the script can read the host name and configure iLO correctly
#  If this is net new hardware rest the default local account "Administrator" password first so it can be used for the initial configuration
#  User Inputs:
#  iLO IP or DNS, Current local account for configuration, New local account to be created
#################################################

# Current issue is with this line: Updates to how the HPIloCMDlets use the Powershell Gallery, so this is outdated for loading the module.
# $ModulePath = "C:\Program Files (x86)\Hewlett Packard Enterprise\PowerShell\Modules\HPEiLOCmdlets\HPEiLOCmdlets.psd1"

# Some form of these should worK but is untested:
# PS> Install-Module -Name HPEiLOCmdlets -RequiredVersion 3.0.0.0
# PS> Import-Module HPEiLOCmdlets
# PS> Get-Command -Module HPEiLOCmdlets

#Initialize Variables
$LocalAccountUN = ""
$LocalAccountPW = ""
$Cred = ""
$iLOName = ""
$ServerName = ""
$ILoLicense = "" #OneView Advanced License
$LicenseType = ""
$LDAPServer = ""
$LDAPUC = ""
$Group1Name = ""
$Group2Name = ""
$Group3Name = ""
$Group4Name = ""
$SNMPLocation = ""
$SNMPContact = ""
$SNMPString = ""
$LocalAccountList = ""
$LocalAccounts = ""
$LocalAccountUN = "" # The account to use for the $LocalAccountPW prompt later.
$AccountRemoval = ""

#Gather iLO IP address and credentials to access the iLO 
$Address = Read-Host -Prompt 'Input iLO DNS name or IP'
$Cred = Get-Credential -Message "Please input username and password to Login into the iLO for the configuration"

#Gather Local account to be created if cpqmon account is not present
$LocalAccountPW = Read-Host -Prompt "Please input Password of the Local Account Username account to be created if additional user account is not already configured"

#Open Connection to iLO
$Connection = Connect-HPEiLO -IP $Address -Credential $Cred -DisableCertificateAuthentication

#Check Advanced licnse and add
$LicenseType = Get-HPEiLOLicense -Connection $Connection
if ($LicenseType.License -notcontains "iLO Advanced") {
    Set-HPEiLOLicense -Connection $Connection -Key $ILoLicense
} # End If

#Creates local admin account if needed and removes Default Local accounts if needed
$LocalAccountList = Get-HPEiLOUser -Connection $Connection
$LocalAccounts = $LocalAccountList.UserInformation

#iLO4 specific settings
If ($Connection.iLOGeneration -eq "iLO4") {
    #Configure LDAP Directory Settings
    Set-HPEiLODirectorySetting -Connection $Connection -LDAPDirectoryAuthentication DirectoryDefaultSchema -LocalUserAccountEnabled Yes -DirectoryServerAddress $LDAPServer -DirectoryServerPort '636' -UserContextIndex 1 -UserContext $LDAPUC
    #Set LDAP Groups (can probably loop this better):
    Add-HPEiLODirectoryGroup -Connection $Connection -GroupName $Group1Name -LoginPrivilege Yes -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -Force
    Add-HPEiLODirectoryGroup -Connection $Connection -GroupName $Group2Name -LoginPrivilege Yes -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -Force
    Add-HPEiLODirectoryGroup -Connection $Connection -GroupName $Group3Name -LoginPrivilege Yes -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -Force
    Add-HPEiLODirectoryGroup -Connection $Connection -GroupName $Group4Name -LoginPrivilege Yes -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -Force

    #Configures SNMP settings
    Set-HPEiLOSNMPSetting -Connection $Connection -SystemLocation $SNMPLocation -SystemContact $SNMPContact -ReadCommunity1 $SNMPString -SNMPConnectedVia AgentlessManagement
    Set-HPEiLOSNMPAlertSetting -Connection $Connection -AlertEnabled Yes -TrapSourceIdentifier iLOHostname -ColdStartTrapBroadcast Enabled -SNMPv1Trap Enabled

    #Creates local admin account if needed
    If ($LocalAccounts.LoginName -notcontains $LocalAccountUN) {
        Add-HPEiLOUser -Connection $Connection -Username $LocalAccountUN -LoginName $LocalAccountUN -Password $LocalAccountPW -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -
    }#End If
}#End if (Check iLO 4)
###################################################
# iLO 5 specific settings
If ($Connection.iLOGeneration -eq "iLO5") {
    #Configure LDAP Directory Settings
    Set-HPEiLODirectorySetting -Connection $Connection -LDAPDirectoryAuthentication DirectoryDefaultSchema -LocalUserAccountEnabled Yes -DirectoryServerAddress $LDAPServer -DirectoryServerPort '636' -UserContextIndex 1 -UserContext $LDAPUC
    #Set LDAP Groups (can probably loop this better):
    Add-HPEiLODirectoryGroup -Connection $Connection -GroupName $Group1Name -LoginPrivilege Yes -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -Force
    Add-HPEiLODirectoryGroup -Connection $Connection -GroupName $Group2Name -LoginPrivilege Yes -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -Force
    Add-HPEiLODirectoryGroup -Connection $Connection -GroupName $Group3Name -LoginPrivilege Yes -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -Force
    Add-HPEiLODirectoryGroup -Connection $Connection -GroupName $Group4Name -LoginPrivilege Yes -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -Force
    
    #Configures SNMP settings
    Set-HPEiLOSNMPSetting -Connection $Connection -SystemLocation $SNMPLocation -SystemContact $SNMPContact -ReadCommunity1 $SNMPString
    Set-HPEiLOSNMPAlertSetting -Connection $Connection -AlertEnabled Yes -TrapSourceIdentifier iLOHostname -ColdStartTrapBroadcast Enabled

    #Creates local admin account if needed
    If ($LocalAccounts.LoginName -notcontains $LocalAccountUN) {
        Add-HPEiLOUser -Connection $Connection -Username $LocalAccountUN -LoginName $LocalAccountUN -Password $LocalAccountPW -UserConfigPrivilege Yes -RemoteConsolePrivilege Yes -VirtualMediaPrivilege Yes -iLOConfigPrivilege Yes -VirtualPowerAndResetPrivilege Yes -HostBIOSConfigPrivilege Yes -HostNICConfigPrivilege Yes -HostStorageConfigPrivilege Yes -SystemRecoveryConfigPrivilege Yes
    }#End If
}#End if (Check iLo 5)

#Reconnects with newly Created Account
$Connection = Connect-HPEiLO -IP $Address -Username $LocalAccountUN -Password $LocalAccountPW -DisableCertificateAuthentication

#Removes HPE Default Account if it exists
If ($LocalAccounts.LoginName -contains $AccountRemoval) {
    Remove-HPEiLOUser -Connection $Connection -LoginName $AccountRemoval
}#End If

#Configure DHCP
$ServerName = Get-HPEiLOServerInfo -Connection $Connection
#$ServerName = Get-HPiLOServerName -Server $Address -Username $LocalAccountUN -Password $LocalAccountPW -DisableCertificateAuthentication

$iLOName = $ServerName.ServerName

#If OS host name is Empty prompt user for OS host name.
If ($iLOName -eq "") {
    $iLOName = Read-Host -Prompt 'Input OS Host Name'
}#End If
$iLOName = $iLOName.ToLower() 
Set-HPEiLOSNTPSetting -Connection $Connection -Timezone PST8PDT
Start-Sleep 180
Set-HPEiLOAccessSetting -Connection $Connection -IPMIProtocolEnabled No -VirtualNICEnabled No -ErrorAction SilentlyContinue
Start-Sleep 180
Set-HPEiLOIPv4NetworkSetting -Connection $Connection -InterfaceType Dedicated -DHCPEnabled Yes -DHCPv4Gateway Enabled -DHCPv4StaticRoute Enabled -DHCPv4DomainName Enabled -DHCPv4DNSServer Enabled -DHCPv4WINSServer Disabled -RegisterDDNSServer Enabled -RegisterWINSServer Disabled -PingGateway Enabled -DNSName $iLOName -Force -ErrorAction SilentlyContinue